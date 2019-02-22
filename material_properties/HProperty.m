classdef (Sealed) HProperty < MaterialProperty
    
    methods ( Access = public )
        
        % units are W / m ^ 2 * K
        function obj = HProperty( varargin )
            
            if nargin == 1
                temperatures = MaterialProperty.DEFAULT_TEMPERATURE;
                convection_coefficients = varargin{ 1 };
            elseif nargin == 2
                temperatures = varargin{ 1 };
                convection_coefficients = varargin{ 2 };
            else
                assert( false )
            end
            
            obj = obj@MaterialProperty( temperatures, convection_coefficients );
            
            assert( all( 0 < obj.values( end ) ) );
            
        end
        
        
        function nd_material_property = nondimensionalize( obj, v_factor, t_range )
            
            [ t, v ] = obj.nondimensionalize_impl( v_factor, t_range );
            nd_material_property = HProperty( t, v );
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function fn = get_extreme_fn( ~ )
            
            fn = @max;
            
        end
        
    end
    
end

