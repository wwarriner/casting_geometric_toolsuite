classdef (Sealed) QProperty < MaterialProperty
    
    methods ( Access = public )
        
        function obj = QProperty( cp, t_range )
            
            assert( isa( cp, 'CpProperty' ) );
            
            [ t, v ] = QProperty.compute( cp, t_range );
            obj = obj@MaterialProperty( t, v );
            
            obj.cp = cp;
            
            assert( all( 0 < obj.values( end ) ) );
            
        end
        
        
        function latent_heat = get_latent_heat( obj, liquidus, solidus )
            
            total_heat = obj.lookup_values( liquidus ) - obj.lookup_values( solidus );
            latent_heat = total_heat - obj.get_sensible_heat( liquidus, solidus );
            
            assert( latent_heat >= 0 );
            
        end
        
        
        function sensible_heat = get_sensible_heat( obj, liquidus, solidus )
            
            d_u = liquidus - solidus;
            sensible_heat = ( obj.cp.lookup_values( liquidus ) + obj.cp.lookup_values( solidus ) ) .* d_u;
            
            assert( sensible_heat > 0 );
            
        end
        
        
        function nd_material_property = nondimensionalize( obj, v_factor, t_range )
            
            [ t, v ] = obj.nondimensionalize_impl( v_factor, t_range );
            nd_material_property = QProperty( t, v );
            
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
    
    
    methods ( Access = public, Static )
        
        function fn = get_extreme_fn( ~ )
            
            fn = @min;
            
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

