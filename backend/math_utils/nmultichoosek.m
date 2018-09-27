% modified from https://stackoverflow.com/a/28284672

function combs = nmultichoosek( n, k )

if n == 1
    combs = nchoosek( n + k - 1, k );
else
    combs = bsxfun( ...
        @minus, ...
        nchoosek( 1 : ( n + k - 1 ), k ), ...
        0 : ( k - 1 ) ...
        );
    combs = reshape( combs, [], k );
end

end

