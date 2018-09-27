function u_pair_mean = pair_mean( u )

u_pair_mean = [];
if length( u ) < 2; return; end

u_pair_mean = ( u( 1 : end - 1 ) + u( 2 : end ) ) ./ 2;

end

