function s = integrate_on_sphere_surface( func_theta_phi )

    function s = integrand( theta, phi )
        
        weight = sin( phi - ( pi / 2 ) );
        value = func_theta_phi( theta, phi );
        s = value .* weight;
        
    end

s = integral2( @integrand, -pi, pi, 0, pi, 'method', 'iterated' ,'AbsTol',1e-6,'RelTol',1e-3 );

end

