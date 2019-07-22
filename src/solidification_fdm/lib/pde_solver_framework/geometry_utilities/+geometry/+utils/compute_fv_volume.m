function [ volume, centroid ] = compute_fv_volume( fv )

% see https://wwwf.imperial.ac.uk/~rn/centroid.pdf
% and http://www.alecjacobson.com/weblog/?p=3854

A = fv.vertices( fv.faces( :, 1 ), : );
B = fv.vertices( fv.faces( :, 2 ), : );
C = fv.vertices( fv.faces( :, 3 ), : );

N = cross( B - A, C - A, 2 );

V = dot( A, N );
volume = sum( V( : ) ) / 6.0;

centroid = ...
    ( 1 / ( 48 * volume ) ) ...
    * sum( N .* ( ( A+B ) .^ 2 + ( B+C ) .^ 2 + ( C+A ) .^ 2 ) );

end

