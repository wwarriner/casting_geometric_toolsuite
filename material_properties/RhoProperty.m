classdef (Sealed) RhoProperty < MaterialProperty
    
    methods ( Access = public )
        
        % units are kg / m ^ 3
        function obj = RhoProperty( varargin )
            
            if nargin == 1
                temperatures = MaterialProperty.DEFAULT_TEMPERATURE;
                rho = varargin{ 1 };
            elseif nargin == 2
                temperatures = varargin{ 1 };
                rho = varargin{ 2 };
            else
                assert( false )
            end
            
            obj = obj@MaterialProperty( temperatures, rho );
            
            assert( all( 0 < obj.values( end ) ) );
            
        end
        
    end
    
end

