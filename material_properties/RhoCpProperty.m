classdef (Sealed) RhoCpProperty < MaterialProperty
    
    methods ( Access = public )
        
        function obj = RhoCpProperty( rho, cp )
            
            assert( isa( rho, 'RhoProperty' ) );
            assert( isa( cp, 'CpProperty' ) );
            
            [ t, v ] = RhoCpProperty.compute( rho, cp );
            obj = obj@MaterialProperty( t, v );
            
            assert( all( 0 < obj.values( end ) ) );
            
        end
        
        
        function nd_material_property = nondimensionalize( obj, v_factor, t_range )
            
            [ t, v ] = obj.nondimensionalize_impl( v_factor, t_range );
            nd_material_property = RhoCpProperty( t, v );
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function fn = get_extreme_fn( ~ )
            
            fn = @max;
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function [ t, v ] = compute( rho, cp )

            t = unique( [ rho.temperatures cp.temperatures ] );
            rho_v = rho.lookup_values( t );
            cp_v = cp.lookup_values( t );
            v = rho_v .* cp_v;
            
        end
        
    end
    
end

