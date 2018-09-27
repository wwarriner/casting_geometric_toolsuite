function values = compute_node_values( graph, edge_weight_func, base_values )

% input: graph, edge_func
% output: list of values, length is node count of graph
% applies edge_func to all nodes in graph
% edge_func takes as input a list of edges, outputs a scalar

if nargin < 3
    base_values = zeros( numnodes( graph ), 1 );
end

t = graph.Edges;
t.EndNodes = fliplr( t.EndNodes );
t = [ graph.Edges; t ];
t.EndNodes = t.EndNodes( :, 1 );
dummy = num2cell( [ 1 : numnodes( graph ); zeros( size( t, 2 ) - 1, numnodes( graph ) ) ].' );
t = [ t; dummy ];
t = sortrows( t, 1, 'ascend' );
t = varfun( edge_weight_func, t, 'groupingvariables', 1, 'inputvariables', { 'Weight' } );
values = t.Fun_Weight .* base_values( : );

end

