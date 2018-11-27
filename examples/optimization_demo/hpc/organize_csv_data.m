function results = organize_csv_data( results_dir, stl_name )
%% get file names
extension = '.csv';
pattern = sprintf( '*%s*%s', stl_name, extension );
file_names = strip( string( ls( fullfile( results_dir, pattern ) ) ) );

%% sort file names by number
pattern = sprintf( '^.*?([0-9]*?)_([0-9]+?)%s', extension );
numbers = regexpi( file_names, pattern, 'tokens' );
numbers = cellfun( @( x ) str2double( x{ : } ), numbers, 'uniformoutput', false );
numbers = cell2mat( numbers );
[ ~, indices ] = sortrows( numbers, 2, 'ascend' );
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

%% append useful data
results.Properties.UserData.Name = stl_name;
results.Properties.UserData.DecisionEndColumn = OrientationBaseCase.get_decision_variable_count();
results.Properties.UserData.ObjectiveStartColumn = results.Properties.UserData.DecisionEndColumn + 1;
OBJECTIVE_VARIABLES_NAME = 'objective_variables';
OBJECTIVE_VARIABLES_EXT = '.json';
job_ids = sort( numbers( :, 1 ), 'ascend' );
objectives_path = [];
if all( isnan( job_ids ) )
    trial_objectives_path = fullfile( ...
        results_dir, ...
        [ OBJECTIVE_VARIABLES_NAME OBJECTIVE_VARIABLES_EXT ] ...
        );
    if isfile( trial_objectives_path )
        objectives_path = trial_objectives_path;
    end 
else
    for i = 1 : length( job_ids )
        
        objectives_name = sprintf( ...
            '%s_%i%s', ...
            OBJECTIVE_VARIABLES_NAME, ...
            job_ids( i ), ...
            OBJECTIVE_VARIABLES_EXT ...
            );
        objectives_path = fullfile( results_dir, objectives_name );
        if isfile( objectives_path )
            break;
        end
        
    end
end
if isempty( objectives_path )
    warning( ...
        [ 'Unable to located objectives path in results dir\n' ...
        '%s' ], ...
        results_dir ...
        );
end
results.Properties.UserData.ObjectiveVariablesPath = objectives_path;

%% mark pareto frontier
pareto_indices = find_pareto_indices( results{ :, results.Properties.UserData.ObjectiveStartColumn : end } );
is_pareto_dominant = false( count, 1 );
is_pareto_dominant( pareto_indices ) = true;
results.is_pareto_dominant = is_pareto_dominant;
results = movevars( results, 'is_pareto_dominant', 'before', results.Properties.UserData.ObjectiveStartColumn );
results.Properties.UserData.ParetoIndicesColumn = results.Properties.UserData.ObjectiveStartColumn;
results.Properties.UserData.ObjectiveStartColumn = results.Properties.UserData.ObjectiveStartColumn + 1;

end

