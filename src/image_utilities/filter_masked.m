function masked = filter_masked( array, mask, amount )
% @filter_masked applies imhmax filtering only to the masked part of an array

masked = array;
masked( ~mask ) = min( masked, [], 'all' );
max_value = max( masked, [], 'all' );
if max_value <= 0
    return;
end
% normalized because imhmax only operates on matrices scaled in the
% range [ 0, 1 ]
masked = max_value .* imhmax( ...
    masked ./ max_value, ...
    amount ./ max_value ...
    );
masked( ~mask ) = array( ~mask );

end