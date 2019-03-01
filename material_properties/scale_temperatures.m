function t_s = scale_temperatures( t, t_in_range, t_out_range )

if nargin < 3
    t_out_range = [ 0 1 ];
end

t_nd = interp1( t_in_range, [ 0 1 ], t, 'linear', 'extrap' );
t_s = interp1( [ 0 1 ], t_out_range, t_nd, 'linear', 'extrap' );

end

