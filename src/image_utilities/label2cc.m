function cc = label2cc( label_matrix )

count = max( label_matrix, [], 'all' );
assert( ~any( label_matrix > count, 'all' ) );

cc = bwconncomp( [] );
cc.ImageSize = size( label_matrix );
cc.NumObjects = double( count );
pixels = cell( count, 1 );
for i = 1 : count
    pixels{ i } = find( label_matrix == i );
end
cc.PixelIdxList = pixels;

end

