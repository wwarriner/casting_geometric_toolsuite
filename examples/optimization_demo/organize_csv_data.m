function results = organize_csv_data( results_dir, stl_name )
%% get file names
extension = '.csv';
pattern = sprintf( '*%s*%s', stl_name, extension );
file_names = strip( string( ls( fullfile( results_dir, pattern ) ) ) );

%% sort file names by number
pattern = sprintf( '^.*?([0-9]*?)%s', extension );
numbers = regexpi( file_names, pattern, 'tokens' );
numbers = cellfun( @( x ) str2double( x{ 1 } ), numbers );
[ ~, indices ] = sortrows( numbers );
file_names = file_names( indices );

%% construct full paths
count = size( file_names, 1 );
file_names = join( [ repmat( results_dir, [ count 1 ] ) file_names ], filesep, 2 );

%% get headers
fid = fopen( file_names( 1 ) );
fc = create_file_closer( fid );
headers = fgetl( fid );
delete( fc );
headers = strsplit( headers, ',' );

%% read data from files
var_count = numel( headers );
results = nan( count, var_count );
for i = 1 : count
    
    fid = fopen( file_names( i ) );
    fc = create_file_closer( fid );
    fgetl( fid );
    values = fgetl( fid );
    delete( fc );
    results( i, : ) = str2double( strsplit( values, ',' ) );
    
end

%% convert to table
results = array2table( results );
results.Properties.VariableNames = headers;

end

