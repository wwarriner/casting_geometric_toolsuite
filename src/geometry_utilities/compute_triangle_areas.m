function areas = compute_triangle_areas( fv )

assert( isstruct( fv ) );
assert( isfield( fv, 'faces' ) );
assert( isfield( fv, 'vertices' ) );

u = fv.vertices( fv.faces( :, 3 ), : ) - fv.vertices( fv.faces( :, 1 ), : );
v = fv.vertices( fv.faces( :, 3 ), : ) - fv.vertices( fv.faces( :, 2 ), : );
areas = 0.5 .* vecnorm( cross( u, v ), 2, 2 );

end

