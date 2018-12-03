function out = map_slice_transform( transform_fn, images_3d, dimension )

[ rot_images_3d, inverses ] = cellfun( ...
    @(x)rotate_to_dimension( dimension, x, 3 ), ...
    images_3d, ...
    'uniformoutput', ...
    false ...
    );
out = nan( size( rot_images_3d{ 1 } ) );
for i = 1 : size( rot_images_3d{ 1 }, 3 )
    
    slices = cellfun( @(x)x( :, :, i ), rot_images_3d, 'uniformoutput', false );
    out( :, :, i ) = transform_fn( slices );
    
end
out = rotate_from_dimension( out, inverses{ 1 } );

end

