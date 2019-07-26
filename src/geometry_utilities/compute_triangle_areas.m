function areas = compute_triangle_areas( fv )

u = fv.vertices( fv.faces( :, 3 ), : ) - fv.vertices( fv.faces( :, 1 ), : );
v = fv.vertices( fv.faces( :, 3 ), : ) - fv.vertices( fv.faces( :, 2 ), : );
n = vecnorm( u ) .* vecnorm( v );
t = sqrt( 1 - ( dot( u, v ) ./ n ) .^ 2 );
areas = n .* t ./ 2;

end

