classdef HProperty < TemperatureDependentPropertyBase
    % units are W / m ^ 2 * K
    
    properties ( Constant )
        name = "h"
    end
    
    methods
        function obj = HProperty( varargin )
            obj = obj@TemperatureDependentPropertyBase( varargin{ : } );
            
            assert( all( 0.0 < obj.values ) );
        end
    end
    
end

