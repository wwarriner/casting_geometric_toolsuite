function phs = qd_plot( ...
    axh, ...
    divisions, ...
    quantiles, ...
    unique_values, ...
    unique_weights ...
    )

assert( isa( axh, 'matlab.graphics.axis.Axes' ) );
assert( all( size( quantiles( : ) ) == size( divisions( : ) ) ) );
assert( all( size( unique_values( : ) ) == size( unique_weights( : ) ) ) );

count = length( quantiles );
phs = cell( count + 1, 1 );
phs{ 1 } = plot( axh, unique_values, unique_weights );
lims = [ axh.XLim; axh.YLim ];
held = ishold( axh );
hold( axh, 'on' );
for i = 1 : count
    
    quantile = quantiles( i );
    division = divisions( i );
    phs{ i + 1 } = plot( ...
        axh, ...
        [ division division axh.XLim( 1 ) ], ...
        [ 0 quantile quantile ], ...
        'k:' ...
        );
    
end

axh.XLim = lims( 1, : );
axh.YLim = lims( 2, : );
if ~held; hold( axh, 'off' ); end

end

