function build_standalone_cli()

path_restorer = fix_path(); %#ok<NASGU>

build_folder = fileparts( mfilename( "fullpath" ) );
root_folder = fullfile( build_folder, ".." );
addpath( root_folder );
extend_search_path();

target_folder = get_target_folder( "cli" );
assert( target_folder ~= build_folder );
assert( target_folder ~= root_folder );
prepare_folder( target_folder )

cache_folder = fullfile( target_folder, "cache" );
assert( cache_folder ~= build_folder );
assert( cache_folder ~= root_folder );
prepare_folder( cache_folder );

build_casting_geometric_toolsuite( cache_folder );
extend_search_path();

% MEX/DLL dependencies
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
copyfile( fullfile( cache_folder, app_name + ".exe" ), target_folder );

res_folder = fullfile( root_folder, "res" );
target_res_folder = fullfile( target_folder, "res" );
copyfile( res_folder, target_res_folder );

cli_res_folder = fullfile( root_folder, "examples", "cli", "res" );
copyfile( cli_res_folder, target_res_folder );

paraview_interface_glob = fullfile( root_folder, "src", "paraview_interface", "*.py" );
target_interface_folder = fullfile( target_res_folder, "interface" );
copyfile( paraview_interface_glob, target_interface_folder );

clear_folder( cache_folder );
rmdir( cache_folder );

zip_file = fullfile( target_folder, app_name + ".zip" );
zip( zip_file, "*", target_folder );

end
