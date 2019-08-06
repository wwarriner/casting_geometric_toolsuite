classdef (Sealed) PhysicalProperties < handle
    % TODO find better name
    % TODO generalize
    % TODO name XBase
    
    properties ( SetAccess = private, Dependent )
        material_id_count(1,1) uint32
        material_ids(:,1) uint32
        ambient_temperature_c(1,1) double {mustBeReal,mustBeFinite}
    end
    
    methods
        function obj = PhysicalProperties()
            obj.ambient = AmbientMaterial.empty();
            obj.melts = containers.Map( ...
                'keytype', 'uint32', ...
                'valuetype', 'any' ...
                );
            obj.materials = containers.Map( ...
                'keytype', 'uint32', ...
                'valuetype', 'any' ...
                );
            obj.convection = Convection.empty();
        end
        
        % INTERFACE, but generalize it here
        function add_material( obj, material )
            assert( ~obj.materials.isKey( material.id ) );
            
            obj.materials( material.id ) = material;
        end
        
        function add_ambient_material( obj, ambient )
            assert( isa( ambient, "AmbientMaterial" ) );
            assert( isempty( obj.ambient ) );
            assert( ~obj.materials.isKey( ambient.id ) );
            
            obj.ambient = ambient;
            obj.add_material( ambient );
        end
        
        function add_melt_material( obj, melt )
            assert( isa( melt, "MeltMaterial" ) );
            assert( ~obj.melts.isKey( melt.id ) );
            assert( ~obj.materials.isKey( melt.id ) );
            
            obj.melts( melt.id ) = melt;
            obj.add_material( melt );
        end
        
        function add_convection( obj, convection )
            obj.convection = convection;
        end
        
        % INTERFACE
        function ready = is_ready( obj )
            ready = true;
            ids = cell2mat( obj.materials.keys() );
            for i = 1 : obj.materials.Count
                m = obj.materials( ids( i ) );
                ready = ready & m.is_ready();
            end
            ready = ready & ~isempty( obj.ambient );
            ready = ready & ~isempty( obj.melts );
            ready = ready & obj.convection.is_ready( cell2mat( obj.materials.keys() ) );
        end
        
        function v = lookup( obj, material_id, property_id, temperatures )
            assert( obj.materials.isKey( material_id ) );
            
            v = obj.materials( material_id ).lookup( property_id, temperatures );
        end
        
        function v = reduce( obj, material_id, property_id, fn )
            assert( obj.materials.isKey( material_id ) );
            
            v = obj.materials( material_id ).reduce( property_id, fn );
        end
        
        function v = lookup_convection_ambient( obj, material_id, temperatures )
            v = obj.lookup_convection( obj.ambient.id, material_id, temperatures );
        end
        
        function v = reduce_convection_ambient( obj, material_id, fn )
            v = obj.reduce_convection( obj.ambient.id, material_id, fn );
        end
        
        function v = lookup_convection( obj, first_material_id, second_material_id, temperatures )
            v = obj.convection.lookup( first_material_id, second_material_id, temperatures );
        end
        
        function v = reduce_convection( obj, first_id, second_id, fn )
            v = obj.convection.reduce( first_id, second_id, fn );
        end
        
        function t = lookup_initial_temperatures( obj, material_id )
            assert( obj.materials.isKey( material_id ) );
            
            t = obj.materials( material_id ).initial_temperature_c;
        end
        
        function value = get_solidus_temperature_c( obj, melt_id )
            assert( obj.melts.isKey( melt_id ) );
            
            m = obj.melts( melt_id );
            value = m.solidus_temperature_c;
        end
        
        function value = get_feeding_effectivity_temperature_c( obj, melt_id )
            assert( obj.melts.isKey( melt_id ) );
            
            m = obj.melts( melt_id );
            value = m.feeding_effectivity_temperature_c;
        end
        
        function value = get_liquidus_temperature_c( obj, melt_id )
            assert( obj.melts.isKey( melt_id ) );
            
            m = obj.melts( melt_id );
            value = m.liquidus_temperature_c;
        end
        
        function value = get_latent_heat_j_per_kg( obj, melt_id )
            assert( obj.melts.isKey( melt_id ) );
            
            m = obj.melts( melt_id );
            value = m.latent_heat_j_per_kg;
        end
        
        function value = get_sensible_heat_j_per_kg( obj, melt_id )
            assert( obj.melts.isKey( melt_id ) );
            
            m = obj.melts( melt_id );
            value = m.sensible_heat_j_per_kg;
        end
        
        function value = get.material_id_count( obj )
            value = numel( obj.material_ids );
        end
        
        function value = get.material_ids( obj )
            value = cell2mat( obj.materials.keys() );
        end
        
        function value = get.ambient_temperature_c( obj )
            value = obj.materials( obj.ambient.id ).initial_temperature_c;
        end
    end
    
    properties ( Access = private )
        ambient AmbientMaterial
        melts containers.Map
        materials containers.Map
        convection Convection
    end
    
end

