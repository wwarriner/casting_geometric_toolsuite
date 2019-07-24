function unprojected = unproject( bounds, height )

assert( ndims( bounds ) == 3 );
assert( size( bounds, 3 ) == 2 );
assert( isa( bounds, 'uint64' ) );

assert( isscalar( height ) );
assert( isa( height, 'uint64' ) );

sz = [ size( bounds, 1 ) size( bounds, 2 ) height ];
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

