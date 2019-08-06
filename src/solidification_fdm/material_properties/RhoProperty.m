classdef RhoProperty < TemperatureDependentPropertyBase
    % units are kg / m ^ 3
    
    properties ( Constant )
        name = "rho"
    end
    
    methods
        function obj = RhoProperty( varargin )
            obj = obj@TemperatureDependentPropertyBase( varargin{ : } );
            
            assert( all( 0.0 < obj.values ) );
        end
    end
    
end

