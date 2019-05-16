classdef (Sealed) PhysicalProperties < handle
    
    methods ( Access = public )
        
        function obj = PhysicalProperties( space_step_in_m )
            
            assert( isscalar( space_step_in_m ) );
            assert( isa( space_step_in_m, 'double' ) );
            assert( isfinite( space_step_in_m ) );
            assert( 0 < space_step_in_m );
            
            obj.space_step = space_step_in_m;
            
            obj.materials = containers.Map( 'KeyType', 'double', 'ValueType', 'any' );
            obj.ambient_id = [];
            obj.melt_ids = [];
            
            obj.primary_melt_id = [];
            obj.primary_melt_id_set = false;
            
            obj.convection = ConvectionProperties.empty();
            
            obj.ambient_material_set = false;
            
            obj.prepared = false;
            
            obj.temperature_range = [];
            
        end
        
        
        function space_step = get_space_step( obj )
            
            space_step = obj.space_step;
            
        end
        
        
        function add_material( obj, material )
            
            assert( ~obj.prepared );
            
            assert( ~isa( material, 'MeltMaterial' ) );
            assert( ~isa( material, 'AmbientMaterial' ) );
            assert( material.is_ready() );
            assert( ~obj.materials.isKey( material.mesh_id ) );
            
            obj.materials( material.mesh_id ) = material;
            
        end
        
        
        function add_ambient_material( obj, material )
            
            assert( ~obj.prepared );
            assert( ~obj.ambient_material_set );
            
            assert( isa( material, 'AmbientMaterial' ) );
            assert( material.is_ready() );
            assert( ~obj.materials.isKey( material.mesh_id ) );
            
            obj.materials( material.mesh_id ) = material;
            obj.ambient_id = material.mesh_id;
            obj.ambient_material_set = true;
            
        end
        
        
        function add_melt_material( obj, material )
            
            assert( ~obj.prepared );
            
            assert( isa( material, 'MeltMaterial' ) );
            assert( material.is_ready() );
            assert( ~obj.materials.isKey( material.mesh_id ) );
            
            obj.melt_ids( end + 1 ) = material.mesh_id;
            if isempty( obj.primary_melt_id )
                obj.assign_primary_melt_id( material.mesh_id );
            end
            obj.materials( material.mesh_id ) = material;
            
        end
        
        
        function assign_primary_melt_id( obj, melt_id )
            
            assert( ismember( melt_id, obj.melt_ids ) );
            
            obj.primary_melt_id = melt_id;
            obj.primary_melt_id_set = true;
            
        end
        
        
        function set_convection( obj, convection )
            
            assert( ~obj.prepared );
            
            obj.convection = convection;
            
        end
        
        
        function ready = is_ready( obj )
            
            ready = true;
            ids = cell2mat( obj.materials.keys() );
            for i = 1 : obj.materials.Count
                
                m = obj.materials( ids( i ) );
                ready = ready & m.is_ready();
                
            end
            ready = ready & obj.convection.is_ready( cell2mat( obj.materials.keys() ) );
            ready = ready & obj.ambient_material_set;
            ready = ready & obj.primary_melt_id_set;
            
        end
        
        
        function prepare_for_solver( obj )
            
            assert( ~obj.prepared );
            assert( obj.is_ready() );
            
            obj.temperature_range = obj.compute_temperature_range();
            ids = cell2mat( obj.materials.keys() );
            for i = 1 : obj.materials.Count
                
                m = obj.materials( ids( i ) );
                m.prepare_for_solver( ...
                    obj.temperature_range ...
                    );
                
            end
            
            obj.prepared = true;
            
        end
        
        
        function temperature = get_ambient_temperature( obj )
            
            temperature = obj.materials( obj.ambient_id ).get_initial_temperature();
            
        end
        
        
        function initial_time_step = compute_initial_time_step( obj )
            
            % based on p421 of Ozisik _Heat Conduction_ 2e, originally from
            % Gupta and Kumar ref 79
            % Int J Heat Mass Transfer, 24, 251-259, 1981
            % see if there are improvements since?
            rho = max( obj.materials( obj.primary_melt_id ).get( Material.RHO ).values );
            [ L, S ] = obj.get_min_latent_heat();
            L = max( L, S ); % if latent heat very small, use sensible heat over freezing range instead
            dx = obj.get_space_step();
            h = -inf;
            ids = obj.materials.keys();
            for i = 1 : obj.materials.Count
                
                id = ids{ i };
                if id == obj.primary_melt_id; continue; end
                h = max( h, max( obj.convection.get( obj.primary_melt_id, id ).values ) );
                
            end
            k = min( obj.materials( obj.primary_melt_id ).get( Material.K ).values );
            Tm = obj.get_feeding_effectivity_temperature( obj.primary_melt_id );
            Tinf = obj.temperature_range( 1 );
            H = h / k;
            numerator = rho * L * dx ^ 2 * ( 1 + H );
            denominator = h * ( Tm - Tinf );
            initial_time_step = numerator / denominator;
            
            assert( initial_time_step > 0 );
            
        end
        
        
        function u_init = generate_initial_temperature_field( obj, fdm_mesh )
            
            assert( obj.prepared );
            
            u_init = nan( size( fdm_mesh ) );
            ids = cell2mat( obj.materials.keys() );
            for i = 1 : obj.materials.Count
                
                id = ids( i );
                u_init( fdm_mesh == id ) = obj.lookup_initial_temperatures( id );
                
            end
            
            assert( ~any( isnan( u_init( : ) ) ) );
            
        end
        
        
        function temperature_range = get_temperature_range( obj )
            
            assert( obj.prepared );
            
            temperature_range = obj.temperature_range;
            
        end
        
        
        function freezing_range = get_freezing_range( obj, melt_id )
            
            assert( obj.prepared );
            
            if nargin < 2
                melt_id = obj.primary_melt_id;
            end
            
            assert( ismember( melt_id, obj.melt_ids ) );
            
            freezing_range = [ ...
                obj.get_liquidus_temperature( melt_id ) ...
                obj.get_solidus_temperature( melt_id ) ...
                ];
            
        end
        
        
        function temperature = get_liquidus_temperature( obj, melt_id )
            
            assert( obj.prepared );
            
            if nargin < 2
                melt_id = obj.primary_melt_id;
            end
            
            assert( ismember( melt_id, obj.melt_ids ) );
            
            m = obj.materials( melt_id );
            temperature = m.get_liquidus_temperature();
            
        end
        
        
        function temperature = get_solidus_temperature( obj, melt_id )
            
            assert( obj.prepared );
            
            if nargin < 2
                melt_id = obj.primary_melt_id;
            end
            
            assert( ismember( melt_id, obj.melt_ids ) );
            
            m = obj.materials( melt_id );
            temperature = m.get_solidus_temperature();
            
        end
        
        
        function fe = get_feeding_effectivity( obj, melt_id )
            
            assert( obj.prepared );
            
            if nargin < 2
                melt_id = obj.primary_melt_id;
            end
            
            assert( ismember( melt_id, obj.melt_ids ) )
            
            fe = obj.materials( melt_id ).get_feeding_effectivity();
            
        end
        
        
        function temperature = get_feeding_effectivity_temperature( obj, melt_id )
            
            assert( obj.prepared );
            
            if nargin < 2
                melt_id = obj.primary_melt_id;
            end
            
            assert( ismember( melt_id, obj.melt_ids ) )
            
            temperature = obj.materials( melt_id ).get_feeding_effectivity_temperature();
            
        end
        
        
        function [ latent_heat, sensible_heat ] = get_min_latent_heat( obj )
            
            assert( obj.prepared );
            
            % use min over melt_materials to be conservative
            latent_heat = inf;
            sensible_heat = nan;
            for id = 1 : obj.materials.Count
                
                if ismember( id, obj.melt_ids )
                    current_lh = obj.materials( id ).get_latent_heat();
                    if current_lh < latent_heat
                        latent_heat = current_lh;
                        sensible_heat = obj.materials( id ).get_sensible_heat();
                    end
                end
                
            end
            assert( latent_heat ~= inf );
            assert( ~isnan( sensible_heat ) );
            
        end
        
        
        function fs = get_fraction_solid( obj, temperatures, melt_id )
            
            assert( obj.prepared );
            
            if nargin < 3
                melt_id = obj.primary_melt_id;
            end
            
            assert( ismember( melt_id, obj.melt_ids ) );

            fs = pp.lookup_values( melt_id, Material.FS, temperatures );
            
        end
        
        
        function q = compute_melt_enthalpies( obj, mesh, temperatures, melt_id )
            
            assert( obj.prepared );
            
            if nargin < 4
                melt_id = obj.primary_melt_id;
            end
            
            assert( numel( mesh ) == numel( temperatures ) );
            
            q = zeros( size( mesh ) );
            q( mesh == melt_id ) = ...
                obj.lookup_values( melt_id, Material.Q, temperatures( mesh == melt_id ) );
            
        end
        
        
        function values = lookup_ambient_values( obj, property_id, temperatures )
            
            assert( obj.prepared );
            
            values = obj.lookup_values( obj.ambient_id, property_id, temperatures );
            
        end
        
        
        function values = lookup_values( obj, material_id, property_id, temperatures )
            
            assert( obj.prepared );
            
            values = obj.materials( material_id ).get( property_id ).lookup_values( temperatures );
            
        end
        
        
        function values = lookup_ambient_h_values( obj, material_id, temperatures )
            
            assert( obj.prepared );
            
            values = obj.lookup_h_values( obj.ambient_id, material_id, temperatures );
            
        end
        
        
        function values = lookup_h_values( obj, first_material_id, second_material_id, temperatures )
            
            assert( obj.prepared );
            
            values = obj.convection.lookup_values( first_material_id, second_material_id, temperatures );
            
        end
        
        
        function initial_temperature = lookup_initial_temperatures( obj, material_id )
            
            initial_temperature = obj.materials( material_id ).get_initial_temperature();
            
        end
        
    end
    
    
    properties ( Access = private )
        
        space_step
        
        materials
        ambient_id
        melt_ids
        
        primary_melt_id
        primary_melt_id_set
        
        convection
        
        ambient_material_set
        
        prepared
        
        temperature_range
        
    end
    
    
    methods ( Access = private )
        
        function temperature_range = compute_temperature_range( obj )
            
            material_count = obj.materials.Count;
            keys = cell2mat( obj.materials.keys() );
            its = zeros( material_count, 1 );
            for i = 1 : material_count
                
                its( i ) = obj.materials( keys( i ) ).get_initial_temperature();
                
            end
            temperature_range = [ min( its ) max( its ) ];
            
        end
        
    end
    
end

