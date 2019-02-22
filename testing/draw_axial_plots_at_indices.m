function phs = draw_axial_plots_at_indices( axhs, shape, field, indices, color_specs )

assert( numel( shape ) == 3 );
assert( numel( shape ) == 3 );
assert( ndims( field ) == 3 );
assert( numel( indices ) == 3 );

r = { ...
    { 1 : shape( 1 ), indices( 2 ), indices( 3 ) } ...
    { indices( 1 ), 1 : shape( 2 ), indices( 3 ) } ...
    { indices( 1 ), indices( 2 ), 1 : shape( 3 ) } ...
    };

color_specs = replicate_color_specs( color_specs, numel( axhs ) );
assert( numel( color_specs ) == 3 );

phs = [];
for i = 1 : numel( axhs )

    r_i = r{ i };
    phs( end + 1 ) = plot( ...
        axhs( i ), ...
        r_i{ i }, ...
        squeeze( field( r_i{ : } ) ), ...
        color_specs{ i } ...
        );
    
end

end

