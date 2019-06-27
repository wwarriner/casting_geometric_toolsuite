function origin = compute_voxel_mesh_origin( envelope, shape, scale )

mesh_lengths = shape .* scale;
origin_offsets = ( mesh_lengths - envelope.lengths ) ./ 2;
origin = envelope.min_point - origin_offsets;

end

