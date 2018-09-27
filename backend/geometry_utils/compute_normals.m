function n = compute_normals( fv )

e1 = fv.vertices( fv.faces( :, 1 ), : ) - fv.vertices( fv.faces( :, 2 ), : );
e1 = e1 ./ vecnorm( e1, 2, 2 );
e2 = fv.vertices( fv.faces( :, 3 ), : ) - fv.vertices( fv.faces( :, 1 ), : );
e2 = e2 ./ vecnorm( e2, 2, 2 );
n = cross( e1, e2, 2 );
n = n ./ vecnorm( n, 2, 2 );

end

