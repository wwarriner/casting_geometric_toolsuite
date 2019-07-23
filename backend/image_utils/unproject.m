function unprojected = unproject( interior, bounds )

assert( ndims( interior ) == 3 );

assert( ndims( bounds ) == 3 );
assert( size( bounds, 3 ) == 2 );
assert( isa( bounds, 'uint64' ) );
assert( isreal( bounds ) );
assert( all( isfinite( bounds ), 'all' ) );
assert( all( bounds >= 0, 'all' ) );
szi = size( interior );
szb = size( bounds );
assert( all( szi( [ 1 2 ] ) == szb( [ 1 2 ] ) ) );

sz = size( interior );
unprojected = false( sz );
for i = 1 : sz( 1 )
    for j = 1 : sz( 2 )
        if ~all( bounds( i, j, : ) > 0 )
            continue;
        end
        unprojected( i, j, bounds( i, j, 1 ) : bounds( i, j, 2 ) ) = true;
    end
end

end

