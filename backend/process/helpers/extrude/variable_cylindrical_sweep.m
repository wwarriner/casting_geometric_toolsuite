function [ X, Y, Z ] = variable_cylindrical_sweep( trajectory, radii )
% Heavily modified from
% Extrude a ribbon/tube and fly through it!
% Teja Muppirala
% v3.1
% Uploaded: 25 Dec 2009
% https://www.mathworks.com/matlabcentral/fileexchange/25086-extrude-a-ribbon-tube-and-fly-through-it-
%
% bases is a 2D array of [ x, y ], where both x and y have length == number
% of slices
% 
% trajectory has length == number of slices
%
% radii are end radii, for caps, vector of length 2
%
% Removes stagnations points ( i.e. consecutive duplicates of trajectory )

C = trajectory;
if size( C, 2 ) == 3 && size( C, 1 ) ~= 3
    
    C = C.';
    
end

% compute sweep circles at each trajectory location

dC = calculate_trajectory_derivative( C );
if dC == zeros( size( C ) )
    X = [];
    Y = [];
    Z = [];
    return;
end
[ C, dC ] = remove_stagnant_points( C, dC );
cross_sections = generate_cross_sections( radii );
sweep = generate_sweep_surface( ...
    cross_sections, ...
    radii( 1 ), ...
    radii( end ), ...
    C, ...
    dC ...
    );

X = squeeze( sweep( 1, :, : ) );
Y = squeeze( sweep( 2, :, : ) );
Z = squeeze( sweep( 3, :, : ) );

[ X, Y, Z ] = fix_nans( X, Y, Z );

end



function cross_sections = generate_cross_sections( radii )

circle_point_spacing = 60;
% -pi lines up sphere with xsecs
t = 2 * pi * linspace( 0, 1, circle_point_spacing ) - pi;
[ R, T ] = meshgrid( radii, t );
cross_sections = cat( ...
    3, ...
    R .* cos( T ), ...
    R .* sin( T ), ...
    zeros( size( R ) ) ...
    );
cross_sections = permute( cross_sections, [ 3 1 2 ] );

end



function dC = calculate_trajectory_derivative( C )

if size( C, 2 ) >= 3
    
    % use a 2nd order approximation for the derivatives of the trajectory
    dC = [ ...
        C( :, 1 : 3 ) * [ -3; 4; -1 ] / 2 ...
        ( C( :, 3 : end ) - C( :, 1 : end - 2 ) ) / 2 ...
        C( :, end - 2 : end ) * [ 1; -4; 3 ] / 2 ...
        ];
    
else
    
    dC = ...
        C( :, [ 2 2 ] ) ...
        - C( :, [ 1 1 ] );
    
end

end



function [ C, dC ] = remove_stagnant_points( C, dC )

dC_stagnant = ( sum( abs( dC ), 1 ) == 0 );
stagnant_indices = find( dC_stagnant, 1 );
if ~isempty( stagnant_indices )
    
    changing_indices = find( ~dC_stagnant );
    C = C( :, changing_indices );
    dC = dC( :, changing_indices );
    
end

end



function sweep = generate_sweep_surface( ...
    cross_sections, ...
    start_radius, ...
    end_radius, ...
    C, ...
    dC ...
    )

xsec_point_count = size( cross_sections, 2 );
slice_count = size( dC, 2 );
sweep = nan( 3, xsec_point_count, slice_count );
for slice_index = 1 : slice_count
    
    sweep( :, :, slice_index ) = orient_and_translate( ...
        cross_sections( :, :, slice_index ), ...
        dC( :, slice_index ) / vecnorm( dC( :, slice_index ) ), ...
        C( :, slice_index ) ...
        );

end

[ start, finish ] = generate_spherical_caps( ...
    xsec_point_count, ...
    start_radius, ...
    end_radius, ...
    dC, ...
    C ...
    );
sweep = cat( 3, start, sweep );
sweep = cat( 3, sweep, finish );

end



function [ start, finish ] = generate_spherical_caps( ...
    point_count, ...
    start_radius, ...
    end_radius, ...
    dir_vec, ...
    translation ...
    )

sphere_point_count = point_count - 1;
[ x, y, z ] = sphere( sphere_point_count );
cap = cat( 3, x, y, z );
start_i = floor( sphere_point_count / 2 );
start = cap( 1 : start_i, :, : );
start = transform_cap( ...
    start, ...
    start_radius, ...
    dir_vec( :, 1 ) ./ vecnorm( dir_vec( :, 1 ) ), ...
    translation( :, 1 ) ...
    );

finish_i = ceil( sphere_point_count / 2 ) + 2;
finish = cap( finish_i : end, :, : );
finish = transform_cap( ...
    finish, ...
    end_radius, ...
    dir_vec( :, end ) ./ vecnorm( dir_vec( :, end ) ), ...
    translation( :, end ) ...
    );

end



function cap = transform_cap( cap, radius, direction, translation )

cap = permute( cap, [ 3 2 1 ] );
%cap = flip( cap, 2 ); % remove reflection caused by permuting
a = size( cap, 2 );
b = size( cap, 3 );
cap = reshape( cap, 3, a * b );

cap = radius * cap;
cap = orient_and_translate( cap, direction, translation );
cap = reshape( cap, 3, a, b );

end



function vectors = orient_and_translate( ...
    vectors, ...
    direction, ...
    translation ...
    )

vec_length = size( vectors, 2 );

% orient
if isequal( direction, [ 0; 0; -1 ] ) % prevents a 0/0 = nan
    
    d = [ 0; 1; 0 ];
    
else
    
    d = ( [ 0; 0; 1 ] + direction ) / 2;
    d = d / norm( d );
    
end
d = repmat( d, 1, vec_length );
vectors = ( d * diag( dot( d, vectors ) ) * 2 ) - vectors;

% translate
vectors = vectors + repmat( translation, 1, vec_length );

end



function [ X, Y, Z ] = fix_nans( X, Y, Z )

is_nan = find( isnan( X( 1, : ) ), 1 );
is_not_nana = find( ~isnan( X( 1, : ) ) );
if ~isempty( is_nan )
    
    warning('NaN''s found, removing');
    X = X( :, is_not_nana );
    Y = Y( :, is_not_nana );
    Z = Z( :, is_not_nana );
    
end

end