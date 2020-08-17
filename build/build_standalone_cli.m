function status = build_standalone_cli()

now = datestr( datetime(), "YYYYmmDD_HHMMSS" );
log_file = sprintf( "cgt_cli_build_%s.log", now );
diary( log_file );
diary_closer = onCleanup( @()diary( "off" ) );

USELESS_WARNINGS = [ ...
    "MATLAB:RMDIR:RemovedFromPath" ...
    "MATLAB:zip:archiveName" ...
    "MATLAB:mpath:nameNonexistentOrNotADirectory" ...
    "MATLAB:mpath:privateDirectoriesNotAllowedOnPath" ... % suitesparse build
    ];
cleaners = cell(1, numel(USELESS_WARNINGS));
for i = 1 : numel(USELESS_WARNINGS)
    w = USELESS_WARNINGS(i);
    warning("off", w);
    cleaners{i} = onCleanup(@()warning("on", w));
end

% TODO pull out testing stuff into separate folder to keep settings files separate
% TODO paraview doesn't understand relative folders passed via env vars, have to convert to absolute file path before passing.

% PREPARE DIRECTORY STRUCTURE
fprintf( "Preparing for build..." );
try
    path_restorer = fix_path(); %#ok<NASGU>
    
    build_folder = fileparts( mfilename( "fullpath" ) );
    root_folder = fullfile( build_folder, ".." );
    addpath( root_folder );
    extend_search_path();
    
    target_folder = get_target_folder( "cli" );
    assert( target_folder ~= build_folder );
    assert( target_folder ~= root_folder );
    prepare_folder( target_folder )
    
    res_folder = fullfile( root_folder, "res" );
    target_res_folder = fullfile( target_folder, "res" );
    
    % PREPARE CACHE
    cache_folder = fullfile( target_folder, "cache" );
    assert( cache_folder ~= build_folder );
    assert( cache_folder ~= root_folder );
    prepare_folder( cache_folder );
catch e
    disp( getReport( e ) );
    error( "Failed to prepare directory structure" );
end
fprintf( "done!" + newline );

% BUILD SUITESPARSE
fprintf( "Building Suitesparse..." + newline );
try
    suitesparse_target = fullfile( cache_folder, "suitesparse" );
    build_suitesparse( suitesparse_target );
catch e
    disp( getReport( e ) );
    error( "Failed to build SuiteSparse" );
end
fprintf( "Done!" + newline );

% BUILD GEOMETRIC TOOLSUITE BACKEND - CACHED
fprintf( "Building backend..." );
try
    build_casting_geometric_toolsuite( cache_folder );
    extend_search_path();
catch e
    disp( getReport( e ) );
    error( "Failed to build CGT backend" );
end
fprintf( "Done!" + newline );

% COMPILE STANDALONE EXECUTABLE - CACHED
fprintf( "Building executable..." );
try
    app_name = "CGT";
    app_file = "cli.m";
    target = "link:exe";
    mcc( ...
        "-T", target, ...
        "-m", ...
        "-d", cache_folder, ...
        "-o", app_name, ...
        "-a", suitesparse_target, ...
        app_file ...
        );
    app_target = app_name + ".exe";
    copyfile( fullfile( cache_folder, app_target ), target_folder );
catch e
    disp( getReport( e ) );
    error( "Failed to build executable" );
end
fprintf( "Done!" + newline );

% COPY RESOURCES
fprintf( "Copying resources..." );
try
    % BACKEND
    copyfile( res_folder, target_res_folder );
    
    % COMMAND LINE
    cli_res_folder = fullfile( root_folder, "examples", "cli", "res" );
    copyfile( cli_res_folder, target_res_folder );
    
    % MODIFY FILE POINTERS IN SETTINGS FILE
    out_settings_file = fullfile( target_res_folder, "steel_sand_casting_cli_settings.json" );
    settings = SettingsFile( out_settings_file );
    settings.paraview.conda.environment_file = "res/environment.yml";
    settings.paraview.interface_folder = "res/interface";
    settings.processes.Casting.input_file = "";
    settings.manager.output_folder = "";
    
    % PARAVIEW INTERFACE
    target_interface_folder = fullfile( target_res_folder, "interface" );
    paraview_interface_glob = fullfile( root_folder, "src", "paraview_interface", "*.py" );
    copyfile( paraview_interface_glob, target_interface_folder );
    paraview_interface_glob = fullfile( root_folder, "src", "paraview_interface", "*.json" );
    copyfile( paraview_interface_glob, target_interface_folder );
catch e
    disp( getReport( e ) );
    error( "Failed to copy resources" );
end
fprintf( "Done!" + newline );

% TEST TARGET
fprintf( "Testing executable..." + newline );
try
    cmd = "NA";
    status = -1;
    cmdout = "NA";
    
    copied_settings_file = fullfile( target_res_folder, "test_settings.json" );
    copyfile( out_settings_file, copied_settings_file );
    settings_remover = onCleanup( @()delete( copied_settings_file ) );
    copied_settings = SettingsFile( copied_settings_file );
    
    p = Paraview( copied_settings );
    installed = p.check_conda_installation();
    if ~installed
        status = 255;
        error( "Test failed: conda not installed." );
    end
    
    output_folder = GetFullPath( fullfile( root_folder, "build_output" ), "/" );
    output_remover = onCleanup( @()rmdir( output_folder, "s" ) );
    copied_settings.manager.output_folder = output_folder;
    
    input_file = GetFullPath( fullfile( ...
        root_folder, "sample_geometries", "bearing_block.stl" ), "/" );
    copied_settings.processes.Casting.input_file = input_file;
    
    copied_settings.processes.Mesh.desired_element_count = 1e5;
    
    cd_cmd = sprintf( "CD ""%s"" && ", GetFullPath( target_folder, "/" ) );
    target_file = GetFullPath( fullfile( target_folder, app_target ), "/" );
    settings_file = GetFullPath( copied_settings_file, "/" );
    start_cmd = sprintf( ...
        "%s ""%s"" ""-ap"" && ", target_file, settings_file );
    exit_cmd = sprintf( "EXIT /B %%ERRORLEVEL%%" + newline );
    cmd = cd_cmd + start_cmd + exit_cmd;
    [status, cmdout] = system( cmd, "-echo" );
    
    rmdir( fullfile( target_interface_folder, "__pycache__" ), "s" ); % cleanup
    if status > 0
        error( "Test failed." );
    end
catch e
    disp( cmd );
    disp( status );
    disp( cmdout );
    disp( getReport( e ) );
    error( "Failed target self-test" );
end
fprintf( "Done!" + newline );

% CREATE DEPLOYABLE ARCHIVE
fprintf( "Creating deployable archive..." );
try
    app_archive = app_name + ".zip";
    zip_file = fullfile( target_folder, app_archive );
    zip( zip_file, "*", target_folder );
catch e
    disp( getReport( e ) );
    error( "Failed to build deployable archive" );
end
fprintf( "Done!" + newline );

% REMOVE CACHE
fprintf( "Cleaning up..." );
try
    clear_folder( cache_folder );
    rmdir( cache_folder );
catch e
    disp( getReport( e ) );
    warning( "Failed to clear cache, continuing..." );
end
fprintf( "Done!" + newline );

end
