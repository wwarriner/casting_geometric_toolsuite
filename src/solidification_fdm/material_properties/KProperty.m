classdef KProperty < TemperatureDependentPropertyBase
    % units are W / m * K
    
    properties ( Constant )
        name = "k"
    end
    
    methods
        function obj = KProperty( varargin )
            obj = obj@TemperatureDependentPropertyBase( varargin{ : } );
            
            assert( all( 0.0 < obj.values ) );
        end
    end
    
end

