function h = update_harmmean( v, h, n )

if nargin < 2
    h = 1;
    n = 0;
end

N = n + numel( v );
h = N / ( sum( 1 ./ v ) + n / h );

end

