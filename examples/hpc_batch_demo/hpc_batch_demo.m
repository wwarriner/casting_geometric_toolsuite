function hpc_batch_demo( stl_file, output_folder, option_file )
%% RESOURCES
options = Options( option_file );
options.set( 'manager.stl_file', stl_file );
options.set( 'manager.output_folder', output_folder ); % needs output path defined
[ ~, name, ~ ] = fileparts( stl_file );

%% ANALYSIS
try
    pm = ProcessManager( options );
    pm.run();
catch e
    fprintf( 1, '%s\n', stl_file );
    fprintf( 1, '%s\n', getReport( e ) );
    assert( false );
end
pm.write();
tbl = pm.generate_summary();

%% OUTPUT
csv_name = sprintf( '%s.csv', name );
output_file = fullfile( output_folder, csv_name );
writetable( tbl, output_file );

end

