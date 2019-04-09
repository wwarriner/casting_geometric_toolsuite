function [ values, weights ] = qd_unique( values, weights )
% weights are between values with the final weight having no meaning
% so the gap between v( i ) and v( i + 1 ) uses w( i )

assert( isvector( values ) );
assert( isnumeric( values ) );
assert( isvector( weights ) );
assert( isnumeric( weights ) );
assert( numel( values ) == numel( weights ) );

samples = sortrows( [ values( : ) weights( : ) ], 1 );

values = samples( :, 1 );
[ unique_values, unique_indices ] = unique( values );

weights = samples( :, 2 );
weights = [ 0; mean( [ weights( 1 : end - 1 ) weights( 2 : end ) ], 2 ) ];
normalized_cumulative_weight = cumsum( weights ) ./ sum( weights );
unique_weights = normalized_cumulative_weight( unique_indices );

[ weights, unique_indices ] = unique( unique_weights );
values = unique_values( unique_indices );

assert( ~isempty( values ) );
assert( ~isempty( weights ) );

end

