function v = qd_interp( ...
    q, ...
    x, ...
    y, ...
    interp_method ...
    )

assert( isvector( q ) );
assert( isnumeric( q ) );
assert( isvector( x ) );
assert( isnumeric( x ) );
assert( isvector( y ) );
assert( isnumeric( y ) );
        
v = interp1( x, y, q, interp_method, 'extrap' );

assert( all( size( q ) == size( v ) ) );
assert( ~any( isnan( v ) ) );

end
