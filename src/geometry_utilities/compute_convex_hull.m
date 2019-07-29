function cfv = compute_convex_hull( fv )

assert( isstruct( fv ) );
assert( isfield( fv, 'faces' ) );
assert( isfield( fv, 'vertices' ) );

faces = convhulln( fv.vertices );
[ u, ~, i ] = unique( faces );
cfv.vertices = fv.vertices( u, : );
cfv.faces = reshape( i, size( faces ) );

end

