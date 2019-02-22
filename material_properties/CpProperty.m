classdef (Sealed) CpProperty < MaterialProperty
    
    methods ( Access = public )
        
        % units are J / kg * K
        function obj = CpProperty( varargin )
            
            if nargin == 1
                temperatures = MaterialProperty.DEFAULT_TEMPERATURE;
                cp = varargin{ 1 };
            elseif nargin == 2
                temperatures = varargin{ 1 };
                cp = varargin{ 2 };
            else
                assert( false )
            end
            
            obj = obj@MaterialProperty( temperatures, cp );
            
            assert( all( 0 < obj.values( end ) ) );
            
        end
        
        
        function nd_material_property = nondimensionalize( obj, v_factor, t_range )
            
            [ t, v ] = obj.nondimensionalize_impl( v_factor, t_range );
            nd_material_property = CpProperty( t, v );
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function fn = get_extreme_fn( ~ )
            
            fn = @min;
            
        end
        
    end
    
end

