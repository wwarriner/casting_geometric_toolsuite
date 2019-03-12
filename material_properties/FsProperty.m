classdef (Sealed) FsProperty < MaterialProperty
    
    methods ( Access = public )
        
        % unitless ratio in range [ 0, 1 ]
        function obj = FsProperty( temperatures, fractions_solid )
            
            obj = obj@MaterialProperty( temperatures, fractions_solid );
            
            if ~isnan( obj.temperatures )
                first_liquid = find( obj.values == 0, 1, 'first' );
                last_solid = find( obj.values == 1, 1, 'last' );
                obj.temperatures = obj.temperatures( last_solid : first_liquid );
                obj.values = obj.values( last_solid : first_liquid );
            end
            
            assert( obj.values( end ) == 0.0 ); % fully liquid at >= max temp
            assert( obj.values( 1 ) == 1.0 ); % fully solid at <= min temp
            
        end
        
        
        function temperature = get_liquidus( obj )
            
            ind = find( obj.values == 0, 1, 'first' );
            temperature = obj.temperatures( ind );
            
        end
        
        
        function temperature = get_solidus( obj )
            
            ind = find( obj.values == 1, 1, 'last' );
            temperature = obj.temperatures( ind );
            
        end
        
    end
    
end

