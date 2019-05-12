function data = legacy_demo( input_path, output_path )
%% RESOURCES
this_path = fileparts( mfilename( 'fullpath' ) );
res_path = fullfile( this_path, 'res' );
option_path = fullfile( res_path, 'legacy_demo_options.json' );

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
summaries = cell( input_count, 1 );
for i = 1 : input_count
    
    options = Options( '', option_path, stl_paths{ i }, output_path );
    try
        data{ i } = legacy_run( options );
    catch e
        fprintf( 1, '%s\n', getReport( e ) );
        fprintf( 1, '%s\n', stl_paths{ i } );
        break;
    end

    %% CREATE TABLE
    count = data{ i }.get_count();
    summary = table;
    keys = data{ i }.to_string();
    for j = 1 : count
        result = data{ i }.get( keys{ j } );
        values = result.to_summary( result.NAME );
        summary = [ summary values ];
    end
    [ ~, name, ~ ] = fileparts( stl_paths{ i } );
    summary.Properties.RowNames = { name };
    summaries{ i } = summary;
    
end

%% MERGE TABLES
tbl = table;
for i = 1 : input_count
    
    if ~isempty( summaries{ i } )
        tbl = [ tbl; summaries{ i } ];
    end
    
end

t = datestr( datetime, 'yyyymmdd_HHMMSS' );
name = sprintf( 'data_%s.csv', t );
output_file = fullfile( output_path, name );
writetable( tbl, output_file );

end