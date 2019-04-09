%% unsorted
rng( 1618 )
values = [ 0; 5 * rand( 100, 1 ) ];
weights = [ rand( 100, 1 ) .^ 2; 0 ];

%% quantiles to divisions
QUANTILES = [ 0.05 0.25 0.5 0.75 0.95 ];
div = quant_to_div( QUANTILES, values, weights );
plot_quantiles( QUANTILES, values, weights );
plot_quantiles( QUANTILES, values ); % uniform weights

%% divisions to quantiles
DIVISIONS = 1 : 4;
quant = div_to_quant( DIVISIONS, values, weights );
plot_divisions( DIVISIONS, values, weights );
plot_divisions( DIVISIONS, values ); % uniform weights

%% unsorted
plot_quantiles( QUANTILES, sort( values ), sort( weights ) );
plot_divisions( DIVISIONS, sort( values ), sort( weights ) );

%% repetition
values = [ 1 2 2 3 4 4 4 4 5 ];
plot_quantiles( QUANTILES, values );

%% uniform weights
div_u = quant_to_div( QUANTILES, values );
quant_u = div_to_quant( DIVISIONS, values );
