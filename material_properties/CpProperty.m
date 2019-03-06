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
        
        
        function q = compute_q_property( obj, t_range )
            
            q = QProperty( obj, t_range );
            
        end
        
    end
    
end

