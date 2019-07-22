classdef (Sealed) AmbientMaterial < property.Material
    
    methods ( Access = public )
        
        function obj = AmbientMaterial( varargin )
            
            obj@property.Material( varargin{ : } );
            
            obj.set( RhoProperty( 1.225 ) ); % kg / m ^ 3
            obj.set( CpProperty( 1006 ) ); % J / kg * K
            obj.set( KProperty( 0.024 ) ); % W / m * K
            obj.set_initial_temperature( 25 ); % C
            
        end
        
    end
    
end

