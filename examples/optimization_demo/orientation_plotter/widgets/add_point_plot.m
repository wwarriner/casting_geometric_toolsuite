function plot_handle = add_point_plot( points )

[ PHI_INDEX, THETA_INDEX ] = unit_sphere_plot_indices();
plot_handle = plotm( points( :, THETA_INDEX ), points( :, PHI_INDEX ) );

end

