function merged = merge_graphs( lhs, rhs )

if size( lhs.Nodes, 1 ) == 0
    
    merged = rhs;
    
elseif size( rhs.Nodes ) == 0
    
    merged = lhs;
    
else
    
    rhs_edges = rhs.Edges;
    rhs_edges.EndNodes( :, : ) = rhs_edges.EndNodes( :, : ) + size( lhs.Nodes, 1 );
    merged = graph( [ lhs.Edges; rhs_edges ], [ lhs.Nodes; rhs.Nodes ] );
    
end

end

