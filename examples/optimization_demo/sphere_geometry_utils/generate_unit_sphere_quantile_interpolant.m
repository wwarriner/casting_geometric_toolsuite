function interpolant = generate_unit_sphere_quantile_interpolant( ...
    gridded_thetas, ...
    gridded_phi_theta_values, ...
    interp_method ...
    )
%% DETERMINE WEIGHTS
weights = abs( sin( gridded_thetas ) );

%% GENERATE QUANTILE INTERPOLANT FROM CDF DATA
VIS_TOL = 1e-2;
interpolant = @(q)quant_to_div( q, gridded_phi_theta_values( : ), weights( : ), interp_method );
%interpolant = @(q)quant_to_div( q, gridded_phi_theta_values( : ), qd_uniform_weights( gridded_phi_theta_values( : ) ), interp_method, VIS_TOL );

end

