function hpc_batch_demo( stl_path, output_path, option_path, solver_path )
%% RESOURCES
options = Options( '', option_path, stl_path, output_path );
[ ~, name, ~ ] = fileparts( stl_path );

if options.use_thermal_profile
    addpath( genpath( solver_path ) );
end

%% ANALYSIS
try
    pm = ProcessManager( options );
    pm.run();
catch e
    fprintf( 1, '%s\n', getReport( e ) );
    fprintf( 1, '%s\n', stl_path );
end
tbl = pm.generate_summary();

%% OUTPUT
csv_name = sprintf( '%s.csv', name );
output_file = fullfile( output_path, csv_name );
writetable( tbl, output_file );

end
