function angles = generate_sphere_angles( desired_mean_separation_deg, method, error_cutoff )

if nargin < 2
    method = 'spiral';
end
if nargin < 3
    error_cutoff = 0.02; % works below 6 deg ~1000 points
end

solid_angle = deg2rad( desired_mean_separation_deg ).^ 2;
point_count = ceil( ( 4 * pi ) / solid_angle );

if strcmpi( method, 'spiral' )
    angles = spiral_angles( point_count );
elseif strcmpi( method, 'octahedral' )
    angles = octahedral_angles( point_count, error_cutoff );
end
angles = unique( angles, 'rows' );

% plot_distance_histogram( angles, desired_mean_separation_deg );
% plot_points( angles );

end


function angles = spiral_angles( point_count )

increment = pi .* ( 3 - sqrt( 5 ) );
offset = 2 ./ point_count;

point_index = 0 : ( point_count - 1 );
phi = point_index .* increment;
y = ( ( point_index .* offset ) - 1 ) + ( offset ./ 2 );
r = sqrt( 1 - ( y .^ 2 ) );
x = cos( phi ) .* r;
z = sin( phi ) .* r;

[ az, el, ~ ] = cart2sph( x, y, z );
angles = [ az.' el.' ];

end


function angles = octahedral_angles( point_count, error_cutoff )

count = 1;
a = 4 * pi / point_count;
m_theta = round( pi / sqrt( a ) );
m_theta = 2 * round( m_theta / 2 );
d_theta = pi / m_theta;
d_phi = a / d_theta;
angles = zeros( 2 * point_count, 2 );
for m = 0 : m_theta
    
    theta = pi * m / m_theta;
    if m == 0 || m == m_theta
        angles( count, : ) = [ 0, theta - pi / 2 ];
        count = count + 1;
        continue;
    end
    m_phi_natural = round( 2 * pi * sin( theta ) / d_phi );
    m_phi_octahedral = 4 * round( m_phi_natural / 4 );
    d_phi_des = 2 * pi * sin( theta ) / m_phi_octahedral;
    error = 2 * abs( d_phi - d_phi_des ) / ( d_phi + d_phi_des );
    if error < error_cutoff
        m_phi = m_phi_octahedral;
    else
        m_phi = m_phi_natural;
    end
    
    for n = 1 : m_phi
        
        phi = 2 * pi * n / m_phi;
        angles( count, : ) = [ phi - pi, theta - pi/2 ];
        count = count + 1;
        
    end
    
end
angles = angles( 1 : count, : );

end


function plot_distance_histogram( angles, desired_mean_separation_deg )

[ x, y, z ] = sph2cart( angles( :, 1 ), angles( :, 2 ), 1 );
pts = [ x y z ];
k = zeros( count, 1 );
d = zeros( count, 1 );
for i = 1 : count
    inds = [ 1 : i-1, i+1 : count ];
    [ k_temp, d( i ) ] = dsearchn( pts( inds, : ), pts( i, : ) );
    if k_temp < i
        k( i ) = k_temp;
    else
        k( i ) = k_temp + 1;
    end
end
actual_separation = rad2deg( 2 * asin( d / 2 ) );

figure();
histogram( actual_separation );
axis( 'square' );
line( ...
    [ desired_mean_separation_deg desired_mean_separation_deg ], ...
    ylim, ...
    'Color' ,'r' ...
    );

end


function plot_points( angles )

[ x, y, z ] = sph2cart( angles( :, 1 ), angles( :, 2 ), 1 );

figure();
plot3( x, y, z, 'k.' );
axis( 'equal' );

end