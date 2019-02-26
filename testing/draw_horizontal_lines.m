function phs = draw_horizontal_lines( axhs, y, color_specs )

color_specs = replicate_color_specs( color_specs, 3 );
assert( numel( color_specs ) == 3 );

phs = [];
for i = 1 : numel( axhs )

    phs( end + 1 ) = plot( ...
        axhs( i ), ...
        axhs( i ).XLim, ...
        [ y y ], ...
        color_specs{ i } ...
        );
    
end

end

