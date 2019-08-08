classdef CpProperty < TemperatureDependentPropertyBase
    % units are J / kg * K
    
    properties ( Constant )
        name = "cp"
    end
    
    methods
        function obj = CpProperty( varargin )
            obj = obj@TemperatureDependentPropertyBase( varargin{ : } );
            
            assert( all( 0.0 < obj.values ) );
        end
    end
    
end

