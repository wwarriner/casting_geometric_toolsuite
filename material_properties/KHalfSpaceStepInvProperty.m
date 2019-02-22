classdef (Sealed) KHalfSpaceStepInvProperty < MaterialProperty
    
    methods ( Access = public )
        
        function obj = KHalfSpaceStepInvProperty( k, space_step )
            
            assert( isa( k, 'KProperty' ) );
            
            [ t, v ] = KHalfSpaceStepInvProperty.compute( k, space_step );
            obj = obj@MaterialProperty( t, v );
            
            assert( all( 0 < obj.values( end ) ) );
            
        end
        
        
        function nd_material_property = nondimensionalize( obj, v_factor, t_range )
            
            [ t, v ] = obj.nondimensionalize_impl( v_factor, t_range );
            nd_material_property = KHalfSpaceStepInvProperty( t, v );
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function fn = get_extreme_fn( ~ )
            
            fn = @max;
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function [ t, v ] = compute( k, space_step )

            t = k.temperatures;
            v = 0.5 * space_step ./ k.values;
            
        end
        
    end
    
end

