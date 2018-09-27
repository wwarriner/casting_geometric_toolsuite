function generate_process_dependencies( output_path )
%% NODES
[ names, class_names ] = get_process_implementation_names();
count = numel( names );
keys = 1 : count;
names( keys ) = names;
node_map = containers.Map( keys, names );
rev_node_map = containers.Map( names, keys );
node_table = table( ...
    names, ...
    class_names, ...
    'variablenames', { 'Name', 'ClassName' } ...
    );

%% EDGES
edge_names = {};
for i = 1 : count

    dependencies = feval( [ class_names{ i } '.get_dependencies' ] );
    for j = 1 : numel( dependencies )

        edge_names = [ ...
            edge_names; ...
            names( i ) dependencies( j ) ...
            ]; %#ok<AGROW>

    end

end
edge_numbers = cellfun( @(x) rev_node_map( x ), edge_names );
edge_table = table( ...
    edge_numbers, ...
    'variablenames', { 'EndNodes' } ...
    );

%% GRAPH
process_dependency_graph = digraph( edge_table, node_table ); %#ok<NASGU>
save( fullfile( output_path, ProcessDependencies.NAME ), ProcessDependencies.NAME );

end

