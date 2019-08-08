function segments = watershed_masked( image, mask )

assert( isa( image, 'double' ) );
assert( isreal( image ) );

assert( islogical( mask ) );
assert( all( size( mask ) == size( image ) ) );

image( ~mask ) = inf;
segments = double( watershed( image ) );
segments( ~mask ) = 0;

end

