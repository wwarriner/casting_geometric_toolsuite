function shape = compute_voxel_mesh_desired_shape( envelope, scale )

shape = floor( envelope.lengths ./ scale );

end

