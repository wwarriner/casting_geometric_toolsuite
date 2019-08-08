function indices = sub2ind_vec( sz, subs )

N = length( sz );
subs = mat2cell( subs, size( subs, 1 ), ones( N, 1 ) );
indices = sub2ind( sz, subs{ : } );

end

