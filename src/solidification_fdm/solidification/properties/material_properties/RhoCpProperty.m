classdef (Sealed) RhoCpProperty < MaterialProperty
    
    methods ( Access = public )
        function obj = RhoCpProperty( rho, cp )
            assert( isa( rho, 'RhoProperty' ) );
            assert( isa( cp, 'CpProperty' ) );
            
            [ t, v ] = RhoCpProperty.compute( rho, cp );
            obj = obj@MaterialProperty( t, v );
        end
    end
    
    methods ( Access = private, Static )
        function [ t, v ] = compute( rho, cp )
            t = unique( [ rho.temperatures; cp.temperatures ] );
            rho_v = rho.lookup_values( t );
            cp_v = cp.lookup_values( t );
            v = rho_v .* cp_v;
        end
    end
    
end

