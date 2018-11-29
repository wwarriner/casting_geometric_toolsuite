function maximizer = max_interpolant( interpolants, do_rescale )

%count = length( interpolants );
    function maximum_value = interp( x, y )
        
        values = cellfun( @(f) f( x, y ), interpolants, 'uniformoutput', false );
        if do_rescale
            values = cellfun( @(v) rescale( v ), values, 'uniformoutput', false );
        end
        values = cat( 3, values{ : } );
        maximum_value = max( values, [], 3 );
        
    end
maximizer = @interp;

end