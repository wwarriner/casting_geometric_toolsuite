classdef (Sealed) QProperty < MaterialProperty
    
    methods ( Access = public )
        function obj = QProperty( cp, t_range )
            assert( isa( cp, 'CpProperty' ) );
            
            [ t, v ] = QProperty.compute( cp, t_range );
            obj = obj@MaterialProperty( t, v );
            obj.cp = cp;
        end
        
        function latent_heat = get_latent_heat( obj, liquidus, solidus )
            total_heat = obj.lookup_values( liquidus ) - obj.lookup_values( solidus );
            latent_heat = total_heat - obj.get_sensible_heat( liquidus, solidus );
            
            assert( latent_heat >= 0 );
        end
        
        function sensible_heat = get_sensible_heat( obj, upper_t, lower_t )
            d_u = upper_t - lower_t;
            sensible_heat = ( obj.cp.lookup_values( upper_t ) + obj.cp.lookup_values( lower_t ) ) .* d_u ./ 2;
            
            assert( sensible_heat > 0 );
        end
        
        function values = lookup_values( obj, temperatures )
            if numel( obj.temperatures ) == 1
                values = obj.values .* ones( size( temperatures ) );
            else
                values = interp1( ...
                    obj.temperatures, ...
                    obj.values, ...
                    temperatures, ...
                    'linear', ...
                    'extrap' ...
                    );
            end
        end
    end
    
    properties ( Access = private )
        cp
    end
    
    methods ( Access = private, Static )
        function [ t, v ] = compute( cp, t_range )
            t_range = sort( t_range( : ) );
            if ~isnan( cp.temperatures )
                t = unique( [ t_range( : ); cp.temperatures ] );
            else
                assert( isscalar( cp.temperatures ) );
                t = t_range;
            end
            q_v = cp.lookup_values( t );
            v = cumtrapz( t, q_v );
        end
    end
    
end

