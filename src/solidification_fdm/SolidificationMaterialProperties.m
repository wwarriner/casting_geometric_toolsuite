classdef SolidificationMaterialProperties < MaterialPropertiesBase
    
    properties ( SetAccess = private, Dependent )
        ambient_temperature_c(1,1) double {mustBeReal,mustBeFinite}
    end
    
    methods
        function obj = SolidificationMaterialProperties()
            obj = obj@MaterialPropertiesBase();
            obj.ambient = AmbientMaterial.empty();
            obj.melts = containers.Map( ...
                'keytype', 'uint32', ...
                'valuetype', 'any' ...
                );
        end
        
        function add_ambient( obj, ambient )
            assert( isa( ambient, "AmbientMaterial" ) );
            assert( isempty( obj.ambient ) );
            
            obj.add( ambient );
            obj.ambient = ambient;
        end
        
        function add_melt( obj, melt )
            assert( isa( melt, "MeltMaterial" ) );
            assert( ~obj.melts.isKey( melt.id ) );
            
            obj.add( melt );
            obj.melts( melt.id ) = melt;
        end
        
        % INTERFACE
        function ready = is_ready( obj )
            ready = is_ready@MaterialPropertiesBase( obj );
            ready = ready & ~isempty( obj.ambient );
            ready = ready & ~isempty( obj.melts );
        end
        
        function t = lookup_initial_temperatures( obj, id )
            assert( obj.has( id ) );
            
            t = obj.materials( id ).initial_temperature_c;
        end
        
        function value = get_solidus_temperature_c( obj, id )
            assert( obj.has( id ) );
            
            m = obj.melts( id );
            value = m.solidus_temperature_c;
        end
        
        function value = get_feeding_effectivity_temperature_c( obj, id )
            assert( obj.has( id ) );
            
            m = obj.melts( id );
            value = m.feeding_effectivity_temperature_c;
        end
        
        function value = get_liquidus_temperature_c( obj, id )
            assert( obj.has( id ) );
            
            m = obj.melts( id );
            value = m.liquidus_temperature_c;
        end
        
        function value = get_latent_heat_j_per_kg( obj, id )
            assert( obj.has( id ) );
            
            m = obj.melts( id );
            value = m.latent_heat_j_per_kg;
        end
        
        function value = get_sensible_heat_j_per_kg( obj, id )
            assert( obj.has( id ) );
            
            m = obj.melts( id );
            value = m.sensible_heat_j_per_kg;
        end
        
        function value = get.ambient_temperature_c( obj )
            value = obj.materials( obj.ambient.id ).initial_temperature_c;
        end
    end
    
    properties ( Access = private )
        ambient AmbientMaterial
        melts containers.Map
    end
    
end

