function offsets = generate_neighbor_offsets( a )

neighbor_subs = generate_neighbor_subs( a );
offsets = sub2ind( sz, num2cell( neighbor_subs ) );
offsets = offsets( : );
offsets( offsets == 0 ) = [];

end

