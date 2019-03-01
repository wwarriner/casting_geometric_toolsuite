classdef (Sealed) QProperty < MaterialProperty
    
    methods ( Access = public )
        
        function obj = QProperty( cp, t_range )
            
            assert( isa( cp, 'CpProperty' ) );
            
            [ t, v ] = QProperty.compute( cp, t_range );
            obj = obj@MaterialProperty( t, v );
            
            assert( all( 0 < obj.values( end ) ) );
            
        end
        
        
        function latent_heat = get_latent_heat( obj, liquidus, solidus )
            
            % todo improve, this includes the non-latent heat as well
            latent_heat = obj.lookup_values( liquidus ) - obj.lookup_values( solidus );
            
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
    
    
    methods ( Access = private, Static )
        
        function [ t, v ] = compute( cp, t_range )

            t_range = sort( t_range( : ) );
            if ~isnan( cp.temperatures )
                t = unique( [ t_range( : ); cp.temperatures ] );
            else
                assert( isscalar( cp.temperatures );
                t = t_range;
            end
            q_v = cp.lookup_values( t );
            v = cumtrapz( t, q_v );
            
        end
        
    end
    
end

