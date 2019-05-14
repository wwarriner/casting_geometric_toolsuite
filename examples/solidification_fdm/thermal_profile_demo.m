function thermal_profile_demo( stl_file, output_path )

option_path = which( 'thermal_profile_demo_options.json' );
options = Options( '', option_path, stl_file, output_path );

try
    pm = ProcessManager( options );
    pm.run();
    pm.write();
catch e
    fprintf( 1, '%s\n', getReport( e ) );
    fprintf( 1, '%s\n', stl_path );
end

end