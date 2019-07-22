function merged = merge_fv( lhs, rhs )

% TODO make more robust
% get list of all fieldnames for both
% set union of fieldnames
% new struct with union of fieldnames
% for each fieldname
%  new struct gets concatenation of underlying data of fieldnames

merged = lhs;
vertex_count = size( merged.vertices, 1 );
merged.faces = [ merged.faces; rhs.faces + vertex_count ];
merged.vertices = [ merged.vertices; rhs.vertices ];
%merged.bodies = [ merged.bodies; rhs.bodies ];

end

