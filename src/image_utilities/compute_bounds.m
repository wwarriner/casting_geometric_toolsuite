function [ bounds, height ] = compute_bounds( image )

assert( ndims( image ) == 3 );
assert( islogical( image ) );

sz = size( image );
[ ~, ~, Z ] = meshgrid( 1 : sz( 2 ), 1 : sz( 1 ), 1 : sz( 3 ) );
Z( ~image ) = nan;

lower = min( Z, [], 3 );
%lower( ~projected_perimeter ) = inf;
%lower = imerode( lower, conndef( 2, 'maximal' ) );
%lower( ~projected_perimeter ) = 0;

upper = max( Z, [], 3 );
%upper( ~projected_perimeter ) = -inf;
%upper = imdilate( upper, conndef( 2, 'maximal' ) );
%upper( ~projected_perimeter ) = 0;

bounds = uint32( cat( 3, lower, upper ) );
height = uint32( sz( 3 ) );

end

