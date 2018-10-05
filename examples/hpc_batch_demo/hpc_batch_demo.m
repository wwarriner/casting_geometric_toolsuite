function hpc_batch_demo( stl_path, output_path )
%% RESOURCES
this_path = fileparts( mfilename( 'fullpath' ) );
res_path = fullfile( this_path, 'res' );
option_path = fullfile( res_path, 'legacy_demo_options.json' );
options = Options( '', option_path, stl_path, output_path );
[ ~, name, ~ ] = fileparts( stl_path );

%% ANALYSIS
try
	tbl = hpc_batch_run( options );
	tbl.Properties.RowNames = { name };
catch e
	fprintf( 1, '%s\n', getReport( e ) );
	fprintf( 1, '%s\n', stl_path );
	return;
end

%% OUTPUT
csv_name = sprintf( '%s.csv', name );
output_file = fullfile( output_path, csv_name );
writetable( tbl, output_file );

end