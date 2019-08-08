function count = count_holes( fv )

assert( isstruct( fv ) );
assert( isfield( fv, 'faces' ) );
assert( isfield( fv, 'vertices' ) );

% Counts holes using euler characteristic Chi
V = size( fv.vertices, 1 );
F = size( fv.faces, 1 );
E = size( determine_edges( fv ), 1 );
Chi = V - E + F;
count = ( 2 - Chi ) / 2;

end

