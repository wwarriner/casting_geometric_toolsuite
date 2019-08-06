classdef AmbientMaterial < SolidificationMaterial
    
    methods ( Access = public )
        function obj = AmbientMaterial()
            obj.add( RhoProperty( 1.225 ) ); % kg / m ^ 3
            obj.add( CpProperty( 1006 ) ); % J / kg * K
            obj.add( KProperty( 0.024 ) ); % W / m * K
        end
    end
    
end

