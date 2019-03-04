classdef (Sealed) KProperty < MaterialProperty
    
    methods ( Access = public )
        
        % units are W / m * K
        function obj = KProperty( varargin )
            
            if nargin == 1
                temperatures = MaterialProperty.DEFAULT_TEMPERATURE;
                conductivities = varargin{ 1 };
            elseif nargin == 2
                temperatures = varargin{ 1 };
                conductivities = varargin{ 2 };
            else
                assert( false )
            end
            
            obj = obj@MaterialProperty( temperatures, conductivities );
            
            assert( all( 0 < obj.values( end ) ) );
            
        end
        
        
        function k_inv = compute_k_half_space_step_inverse_property( obj, space_step )
            
            k_inv = KHalfSpaceStepInvProperty( obj, space_step );
            
        end
        
        
        function nd_material_property = nondimensionalize( obj, v_factor, t_range )
            
            [ t, v ] = obj.nondimensionalize_impl( v_factor, t_range );
            nd_material_property = KProperty( t, v );
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function fn = get_extreme_fn( ~ )
            
            fn = @max;
            
        end
        
    end
    
end

