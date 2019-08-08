classdef FsProperty < TemperatureDependentPropertyBase
    
    properties ( Constant )
        name = "fs"
    end
    
    properties
        feeding_effectivity(1,1) double {...
            mustBeReal,...
            mustBeFinite,...
            mustBeGreaterThanOrEqual(feeding_effectivity,0),...
            mustBeLessThanOrEqual(feeding_effectivity,1)...
            } = 0.5
    end
    
    properties ( SetAccess = private )
        feeding_effectivity_temperature_c(1,1) double {mustBeReal,mustBeFinite}
    end
    
    properties ( SetAccess = private, Dependent )
        solidus_temperature_c(1,1) double {mustBeReal,mustBeFinite}
        liquidus_temperature_c(1,1) double {mustBeReal,mustBeFinite}
    end
    
    methods
        function obj = FsProperty( temperatures, fractions_solid )
            obj = obj@TemperatureDependentPropertyBase( temperatures, fractions_solid );
            
            assert( 2 <= numel( obj.temperatures ) );
            
            assert( all( 0.0 <= obj.values ) );
            assert( all( obj.values <= 1.0 ) );
            
            first_liquid = find( obj.values == 0, 1, 'first' );
            last_solid = find( obj.values == 1, 1, 'last' );
            obj.temperatures = obj.temperatures( last_solid : first_liquid );
            obj.values = obj.values( last_solid : first_liquid );
            
            assert( obj.values( end ) == 0.0 ); % fully liquid at >= max temp
            assert( obj.values( 1 ) == 1.0 ); % fully solid at <= min temp
            
            fet = interp1( ...
                obj.values, ...
                obj.temperatures, ...
                obj.feeding_effectivity, ...
                'linear' ...
                );
            obj.feeding_effectivity_temperature_c = fet;
        end
        
        function value = get.solidus_temperature_c( obj )
            value = obj.temperatures( 1 );
        end
        
        function value = get.liquidus_temperature_c( obj )
            value = obj.temperatures( end );
        end
    end
    
end

