function [ graph, nieghbors ] = remove_neighbor_edges( graph, node, degree )

nieghbors = [];
if degree == 0; return; end

neighbors = nearest( graph, node, 1, 'Method', 'unweighted' );
if isempty( neighbors ); return; end

neighbor_edges = findedge( graph, repmat( node, size( neighbors ) ), neighbors );
graph = rmedge( graph, neighbor_edges );

for i = 1 : length( neighbors )
    
    [ graph, neighbor_nodes ] = remove_neighbor_edges( graph, neighbors( i ), degree - 1 );
    nieghbors = [ nieghbors; neighbor_nodes ]; %#ok<AGROW>
    
end
nieghbors = unique( nieghbors );

end

