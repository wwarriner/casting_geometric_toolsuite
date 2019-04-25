function demo( input_path, output_path )
%% BUILD
res_path = build_demo();

%% RESOURCES
option_path = fullfile( res_path, 'demo_options.json' );

%% INPUT FILE(S)
if isfile( input_path )
    stl_paths = { input_path };
elseif isfolder( input_path )
    stl_paths = get_full_paths_from_listing( ...
        get_files_with_extension( input_path, 'stl' ) ...
        );
else
    error( 'Could not understand input path\n' );
end

%% ANALYSES
input_count = numel( stl_paths );
data = cell( input_count, 1 );
for i = 1 : input_count
    
    stl_path = stl_paths{ i };
    [ ~, stl_name, ~ ] = fileparts( stl_path );
    current_output_path = fullfile( output_path, stl_name );
    options = Options( '', option_path, stl_path, current_output_path );
    try
        pm = ProcessManager( options );
        pm.run();
    catch e
        fprintf( 1, '%s\n', getReport( e ) );
        fprintf( 1, '%s\n', stl_paths{ i } );
    end
    pm.write();
    data{ i } = pm.generate_summary();
    
end

%% DATA
tbl = table;
for i = 1 : input_count
    
    tbl = [ tbl; data{ i } ];
    
end

t = datestr( datetime, 'yyyymmdd_HHMMSS' );
name = sprintf( 'data_%s.csv', t );
output_file = fullfile( output_path, name );
writetable( tbl, output_file );

end