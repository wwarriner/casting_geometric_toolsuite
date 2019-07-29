function angles = compute_draft_angles( normals, up_vector )
% @compute_draft_angles computes the draft angles of faces represented by the
% input normals, with respect to the up vector. The angles returned is pi/2 
% minus the plane angle lying between the up_vector and the normal. Draft is
% minimized when normal is perpendicular to up, and maximized when parallel. The
% angles have units of radian.
% Inputs:
% - @normals is a real, finite, double matrix whose columns are dimensions and
% rows are normal vectors.
% - @up_vector is a real, finite, double row vector.

assert( ismatrix( normals ) );
assert( isa( normals, 'double' ) );
assert( isreal( normals ) );
assert( all( isfinite( normals ), 'all' ) );

assert( isrow( up_vector ) );
assert( isa( up_vector, 'double' ) );
assert( isreal( up_vector ) );
assert( all( isfinite( up_vector ) ) );

if nargin < 2
    up_vector = [ 0 0 1 ];
end

up = repmat( up_vector, [ size( normals, 1 ) 1 ] );
cos_theta = dot( normals, up, 2 ) ...
    ./ ( vecnorm( normals, 2, 2 ) .* vecnorm( up, 2, 2 ) );
angles = abs( pi/2 - acos( cos_theta ) );

end

