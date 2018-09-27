function value = polynomial_value_from_factors( values, degree )

combs = nmultichoosek( numel( values ), degree );
value = sum( prod( values( combs ), 2 ) );

end

