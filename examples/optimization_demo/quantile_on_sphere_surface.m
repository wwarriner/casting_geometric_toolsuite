function divisions = quantile_on_sphere_surface( func_theta_phi, quantiles, interp_method )

    function [ value, weight ] = sample( theta, phi )
        
        weight = abs( sin( phi ) );
        value = func_theta_phi( theta, phi );
        
    end

n = 200;
theta_n = 2 * n + 1;
thetas = linspace( -pi, pi, theta_n );
phi_n = n + 1;
phis = linspace( -pi / 2, pi / 2, phi_n );
[ thetas, phis ] = meshgrid( thetas, phis );
[ values, weights ] = sample( thetas, phis );

% need special case for nearest neighbor interp

samples = [ values( : ) weights( : ) ];
samples = sortrows( samples, 1 );
v = samples( :, 1 );
w = samples( :, 2 );
w_n = cumsum( w ) ./ sum( w );
[ v_subset, w_ind ] = unique( v );
w_subset = w_n( w_ind );
[ w_subset, v_ind ] = unique( w_subset );
v_subset = v_subset( v_ind );
fh = figure( 'color', 'w', 'name', 'Q-Q Plot' );
axh = axes( fh );
hold on;
if length( v_subset ) > 100
    linespec = 'k';
else
    linespec = 'k.';
end
plot( axh, w_subset, rescale( v_subset ), linespec ); axis( 'square' ); xlim( [ 0 1 ] );
plot( axh, [ 0 1 ], [ 0 1 ], 'k:' );
if strcmpi( interp_method, 'nearest' )
    interp_method = 'next';
end
divisions = interp1( w_subset, v_subset, quantiles, interp_method );
qq_divisions = interp1( w_subset, rescale( v_subset ), quantiles, interp_method );
for i = 1 : length( divisions )
    
    plot( axh, quantiles, qq_divisions, 'r+' );
    
end

end

