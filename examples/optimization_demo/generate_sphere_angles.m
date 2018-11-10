function angles = generate_sphere_angles( point_count )

increment = pi .* ( 3 - sqrt( 5 ) );
offset = 2 ./ point_count;

point_index = 0 : ( point_count - 1 );
phi = point_index .* increment;
y = ( ( point_index .* offset ) - 1 ) + ( offset ./ 2 );
r = sqrt( 1 - ( y .^ 2 ) );
x = cos( phi ) .* r;
z = sin( phi ) .* r;

%plot3( x, y, z, 'k.', 'linestyle', 'none' );
%hold on;
%axis equal;

[ az, el, ~ ] = cart2sph( x, y, z );
angles = [ az.' el.' ];

end