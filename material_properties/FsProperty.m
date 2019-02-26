classdef (Sealed) FsProperty < MaterialProperty
    
    methods ( Access = public )
        
        % unitless ratio in range [ 0, 1 ]
        function obj = FsProperty( temperatures, fractions_solid )
            
            obj = obj@MaterialProperty( temperatures, fractions_solid );
            
            assert( obj.values( end ) == 0.0 ); % fully liquid at >= max temp
            assert( obj.values( 1 ) == 1.0 ); % fully solid at <= min temp
            
        end
        
        
        function temperature = get_liquidus( obj )
            
            ind = find( obj.values == 1, 1, 'last' );
            temperature = obj.temperatures( ind );
            
        end
        
        
        function temperature = get_solidus( obj )
            
            ind = find( obj.values == 0, 1, 'first' );
            temperature = obj.temperatures( ind );
            
        end
        
        
        function nd_material_property = nondimensionalize( obj, v_factor, t_range )
            
            [ t, v ] = obj.nondimensionalize_impl( v_factor, t_range );
            nd_material_property = FsProperty( t, v );
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function fn = get_extreme_fn( ~ )
            
            fn = @max;
            
        end
        
    end
    
end

