function subs = ind2sub_vec( sz, indices )

indices = indices( : );
N = length( sz );
[ subs{ 1 : N } ] = ind2sub( sz, indices );
subs = cell2mat( subs );

end 