function array = rasterize_fv( fv, points )

array = double( VOXELISE( points{ 1 }, points{ 2 }, points{ 3 }, fv ) );

end

