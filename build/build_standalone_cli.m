function status = build_standalone_cli()

USELESS_WARNINGS = [ ...
    "MATLAB:RMDIR:RemovedFromPath" ...
    "MATLAB:zip:archiveName" ...
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

% BUILD GEOMETRIC TOOLSUITE BACKEND - CACHED
build_casting_geometric_toolsuite( cache_folder );
extend_search_path();

% COMPILE STANDALONE EXECUTABLE - CACHED
lib_folder = fullfile( root_folder, "lib" );
suitesparse_folder = fullfile( lib_folder, "suitesparse_cholmod", "out", "*" );
app_name = "CGT";
app_file = "cli.m";
target = "link:exe";
mcc( ...
    "-T", target, ...
    "-m", ...
    "-d", cache_folder, ...
    "-o", app_name, ...
    "-a", suitesparse_folder, ...
    app_file ...
);
app_target = app_name + ".exe";
copyfile( fullfile( cache_folder, app_target ), target_folder );

% REMOVE CACHE
clear_folder( cache_folder );
rmdir( cache_folder );

% COPY BACKEND RESOURCES
copyfile( res_folder, target_res_folder );

% COPY CLI RESOURCES
cli_res_folder = fullfile( root_folder, "examples", "cli", "res" );
copyfile( cli_res_folder, target_res_folder );
% modify settings
out_settings_file = fullfile( target_res_folder, "cli_settings.json" );
settings = SettingsFile( out_settings_file );
settings.paraview.conda.environment_file = "res/environment.yml";
settings.paraview.interface_folder = "res/interface";
settings.processes.Casting.input_file = "";
settings.manager.output_folder = "";

% COPY PARAVIEW INTERFACE RESOURCES
target_interface_folder = fullfile( target_res_folder, "interface" );
paraview_interface_glob = fullfile( root_folder, "src", "paraview_interface", "*.py" );
copyfile( paraview_interface_glob, target_interface_folder );
paraview_interface_glob = fullfile( root_folder, "src", "paraview_interface", "*.json" );
copyfile( paraview_interface_glob, target_interface_folder );

% TEST TARGET
copied_settings_file = fullfile( target_res_folder, "test_settings.json" );
copyfile( out_settings_file, copied_settings_file );
settings_remover = onCleanup( @()delete( copied_settings_file ) );
copied_settings = SettingsFile( copied_settings_file );
output_folder = GetFullPath( fullfile( root_folder, "build_output" ), "/" );
output_remover = onCleanup( @()rmdir( output_folder, "s" ) );
copied_settings.manager.output_folder = output_folder;
input_file = GetFullPath( fullfile( root_folder, "sample_geometries", "bearing_block.stl" ), "/" );
copied_settings.processes.Casting.input_file = input_file;
cd_cmd = sprintf( "CD ""%s"" && ", GetFullPath( target_folder, "/" ) );
target_file = GetFullPath( fullfile( target_folder, app_target ), "/" );
settings_file = GetFullPath( copied_settings_file, "/" );
start_cmd = sprintf( "START /WAIT %s ""%s"" ""-ap"" && ", target_file, settings_file );
exit_cmd = sprintf( "EXIT /B %%ERRORLEVEL%%" + newline );
cmd = cd_cmd + start_cmd + exit_cmd;
status = system( cmd, "-echo" );
rmdir( fullfile( target_interface_folder, "__pycache__" ), "s" ); % cleanup
if status > 0
    error( "Test failed." );
end

% CREATE DEPLOYABLE ARCHIVE
app_archive = app_name + ".zip";
zip_file = fullfile( target_folder, app_archive );
zip( zip_file, "*", target_folder );

end
