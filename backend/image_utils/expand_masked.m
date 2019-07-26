function expanded = expand_masked( image, mask, threshold )
% @expand_masked functions similarly to dilation, but operates using the
% quasi-euclidean geodesic distance, forcing it to traverse around
% boundaries.
% Inputs:
% - @image is a logical array representing the image to be expanded.
% - @mask is a logical array of the same size as @image, representing the
% boundaries.
% - @threshold is a real, finite, positive, scalar double and has mesh length units, representing
% the cutoff for expansion distance.

assert( islogical( image ) );

assert( islogical( mask ) );
assert( all( size( image ) == size( mask ) ) );

assert( isscalar( threshold ) );
assert( isa( threshold, 'double' ) );
assert( isreal( threshold ) );
assert( isfinite( threshold ) );
assert( 0.0 < threshold );

distances = bwdistgeodesic( mask, image, 'quasi-euclidean' );
distances( isnan( distances ) ) = inf;
expanded = distances <= threshold;
expanded( image ) = 0;

end

