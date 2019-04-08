function v = qd_interp( ...
    q, ...
    x, ...
    y, ...
    interp_method ...
    )

assert( isnumeric( q ) );
assert( isvector( x ) );
assert( isnumeric( x ) );
assert( isvector( y ) );
assert( isnumeric( y ) );
        
v = interp1( x, y, q, interp_method, 'extrap' );

assert( ~any( isnan( v( : ) ) ) );

end
