function areas = compute_triangle_areas( varargin )

if nargin == 1
    fv = varargin{ 1 };
    assert( isstruct( fv ) );
    assert( isfield( fv, 'faces' ) );
    assert( isfield( fv, 'vertices' ) );
    f = fv.faces;
    v = fv.vertices;
elseif nargin == 2
    f = varargin{ 1 };
    v = varargin{ 2 };
else
    assert( false );
end

assert( isa( f, "double" ) );
assert( isreal( f ) );
assert( all( isfinite( f ), "all" ) );
assert( all( 0.0 < f, "all" ) );

assert( isa( v, "double" ) );
assert( isreal( v ) );
assert( all( isfinite( v ), "all" ) );

a = v( f( :, 3 ), : ) - v( f( :, 1 ), : );
b = v( f( :, 3 ), : ) - v( f( :, 2 ), : );
areas = 0.5 .* vecnorm( cross( a, b ), 2, 2 );

end

