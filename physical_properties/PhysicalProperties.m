classdef (Sealed) PhysicalProperties < handle
    
    properties ( Access = public, Constant )
        
        RHO_INDEX = 1;
        CP_INDEX = 2;
        K_INV_INDEX = 3;
        Q_INDEX = 4;
        FS_INDEX = 5;
        
    end
    
    
    methods ( Access = public )
        
        function obj = PhysicalProperties()
            
            obj.space_step = [];
            obj.max_length = [];
            
            obj.materials = containers.Map( 'KeyType', 'double', 'ValueType', 'any' );
            obj.ambient_id = [];
            obj.melt_ids = [];
            
            obj.convection = ConvectionProperties.empty();
            
            obj.space_step_set = false;
            obj.max_length_set = false;
            obj.ambient_material_set = false;
            % TODO at least one other material set?
            
            obj.prepared = false;
            
            obj.extremes = [];
            obj.temperature_range = [];
            
            obj.time_factor = [];
            obj.space_step_nd = [];
            obj.initial_temperatures_nd = containers.Map( 'KeyType', 'double', 'ValueType', 'any' );
            obj.material_properties_nd = containers.Map( 'KeyType', 'double', 'ValueType', 'any' );
            obj.liquidus_temperatures_nd = containers.Map( 'KeyType', 'double', 'ValueType', 'any' );
            obj.fe_temperatures_nd = containers.Map( 'KeyType', 'double', 'ValueType', 'double' );
            obj.solidus_temperatures_nd = containers.Map( 'KeyType', 'double', 'ValueType', 'any' );
            obj.convection_nd = ConvectionProperties.empty();
            
        end
        
        
        % units are m
        function set_space_step( obj, space_step )
            
            assert( ~obj.prepared );
            
            assert( isscalar( space_step ) );
            assert( isa( space_step, 'double' ) );
            assert( isfinite( space_step ) );
            assert( 0 < space_step );
            
            obj.space_step = space_step;
            obj.space_step_set = true;
            
        end
        
        
        function space_step = get_space_step( obj )
            
            space_step = obj.space_step;
            
        end
        
        
        function set_max_length( obj, shape )
            
            assert( ~obj.prepared );
            
            assert( obj.space_step_set );
            
            assert( isvector( shape ) );
            assert( isa( shape, 'double' ) );
            assert( numel( shape ) == 3 );
            assert( all( isfinite( shape ) ) );
            assert( all( 0 < shape ) );
            
            obj.max_length = max( shape ) .* obj.space_step;
            obj.max_length_set = true;
            
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
            obj.materials( material.mesh_id ) = material;
            
        end
        
        
        function set_convection( obj, convection )
            
            assert( ~obj.prepared );
            
            obj.convection = convection;
            
        end
        
        
        function max_length = get_max_length( obj )
            
            max_length = obj.max_length;
            
        end
        
        
        function prepare_for_solver( obj )
            
            assert( ~obj.prepared );
            
            ready = true;
            ids = cell2mat( obj.materials.keys() );
            for i = 1 : obj.materials.Count
                
                ready = ready & obj.materials( ids( i ) ).is_ready();
                
            end
            ready = ready & obj.convection.is_ready( cell2mat( obj.materials.keys() ) );
            ready = ready & obj.space_step_set;
            ready = ready & obj.max_length_set;
            ready = ready & obj.ambient_material_set;
            assert( ready );
            
            obj.space_step_nd = obj.space_step / obj.max_length;
            
            obj.extremes = obj.compute_extremes();
            obj.temperature_range = obj.compute_temperature_range();
            for i = 1 : obj.materials.Count
                
                id = ids( i );
                material_nd = obj.materials( id );%.nondimensionalize( obj.extremes, obj.temperature_range );
                obj.initial_temperatures_nd( id ) = material_nd.get_initial_temperature();
                obj.material_properties_nd( id ) = obj.prepare_properties( material_nd );
                if ismember( id, obj.melt_ids )
                    obj.liquidus_temperatures_nd( id ) = material_nd.get_liquidus_temperature();
                    obj.fe_temperatures_nd( id ) = material_nd.get_feeding_effectivity_temperature();
                    obj.solidus_temperatures_nd( id ) = material_nd.get_solidus_temperature();
                    mps = obj.material_properties_nd( id );
                    mps( obj.FS_INDEX ) = material_nd.get( MeltMaterial.FS_INDEX );
                    obj.material_properties_nd( id ) = mps;
                end
                
            end
            
            convection_extreme = obj.extremes( Material.K_INDEX );%obj.convection.get_extreme();
            obj.convection_nd = obj.convection%;.nondimensionalize( convection_extreme, obj.temperature_range );
            
            obj.time_factor = 1;%obj.extremes( Material.RHO_INDEX ) * ...
                %obj.extremes( Material.CP_INDEX ) * ...
                %obj.max_length ^ 2 / ...
                %obj.extremes( Material.K_INDEX );

            obj.prepared = true;
            
        end
        
        
        function initial_time_step_nd = compute_initial_time_step_nd( obj, primary_melt_id )
            
            % based on p421 of Ozisik _Heat Conduction_ 2e, originally from
            % Gupta and Kumar ref 79
            % Int J Heat Mass Transfer, 24, 251-259, 1981
            % see if there are improvements since?
            rho = obj.extremes( obj.RHO_INDEX );
            L = obj.get_min_latent_heat();
            dx = obj.get_space_step();
            h = obj.convection.get_extreme();
            k = obj.extremes( Material.K_INDEX );
            Tm = obj.get_feeding_effectivity_temperature( primary_melt_id );
            Tinf = obj.temperature_range( 1 );
            H = h / k;
            numerator = rho * L * dx * ( 1 + H * dx );
            denominator = h * ( Tm - Tinf );
            initial_time_step_nd = obj.nondimensionalize_times( numerator / denominator );
            
        end
        
        
        function temperature_range = get_temperature_range( obj )
            
            assert( obj.prepared );
            
            temperature_range = obj.temperature_range;
            
        end
        
        
        function temperature = get_ambient_temperature_nd( obj )
            
            assert( obj.prepared );
            
            temperature = obj.initial_temperatures_nd( obj.ambient_id );
            
        end
        
        
        function u_initial = generate_initial_temperature_field_nd( obj, fdm_mesh )
            
            assert( obj.prepared );
            
            u_initial = nan( size( fdm_mesh ) );
            ids = cell2mat( obj.materials.keys() );
            for i = 1 : obj.materials.Count
                
                id = ids( i );
                u_initial( fdm_mesh == id ) = obj.lookup_initial_temperatures_nd( id );
                
            end
            
            assert( ~any( isnan( u_initial( : ) ) ) );
            
        end
        
        
        function space_step_nd = get_space_step_nd( obj )
            
            assert( obj.prepared );
            
            space_step_nd = obj.space_step_nd;
            
        end
        
        
        % units are s
        function times_nd = nondimensionalize_times( obj, times )
            
            assert( obj.prepared );

            times_nd = times / obj.time_factor;
            
        end
        
        
        function [ latent_heat, sensible_heat ] = get_min_latent_heat( obj )
            
            assert( obj.prepared );
            
            % use min over materials to be conservative
            latent_heat = inf;
            sensible_heat = nan;
            for id = 1 : obj.materials.Count
                
                if ismember( id, obj.melt_ids )
                    [ current_lh, current_sh ] = obj.materials( id ).get_latent_heat( obj.get_temperature_range() );
                    if current_lh < latent_heat
                        latent_heat = current_lh;
                        sensible_heat = current_sh;
                    end
                end
                
            end
            assert( latent_heat ~= inf );
            assert( ~isnan( sensible_heat ) );
            
        end
        
        
        function [ latent_heat, sensible_heat ] = get_min_latent_heat_nd( obj )
            
            assert( obj.prepared );
            
            % use min over materials to be conservative
            latent_heat = inf;
            sensible_heat = nan;
            for id = 1 : obj.materials.Count
                
                if ismember( id, obj.melt_ids )
                    mp_nd = obj.material_properties_nd( id );
                    liquidus = mp_nd( obj.FS_INDEX ).get_liquidus();
                    solidus = mp_nd( obj.FS_INDEX ).get_solidus();
                    current = max( mp_nd( obj.Q_INDEX ).get_latent_heat( liquidus, solidus ) );
                    if current < latent_heat
                        latent_heat = current;
                        sensible_heat = mp_nd( obj.Q_INDEX ).get_sensible_heat( liquidus, solidus );
                    end
                end
                
            end
            assert( latent_heat ~= inf );
            assert( ~isnan( sensible_heat ) );
            
        end
        
        
        function q = compute_melt_enthalpies_nd( obj, mesh, temperatures )
            
            assert( obj.prepared );
            
            assert( numel( mesh ) == numel( temperatures ) );
            
            q = zeros( size( mesh ) );
            for material_id = 1 : obj.materials.Count
                
                if ismember( material_id, obj.melt_ids )
                    q( mesh == material_id ) = ...
                        obj.lookup_values( material_id, obj.Q_INDEX, temperatures( mesh == material_id ) );
                end
                
            end
            
        end
        
        
        function values = lookup_ambient_values( obj, property_id, temperatures )
            
            assert( obj.prepared );
            
            values = obj.lookup_values( obj.ambient_id, property_id, temperatures );
            
        end
        
        
        function values = lookup_values( obj, material_id, property_id, temperatures )
            
            assert( obj.prepared );
            
            mps = obj.material_properties_nd( material_id );
            values = mps( property_id ).lookup_values( temperatures );
            
        end
        
        
        function values = lookup_ambient_h_values( obj, material_id, temperatures )
            
            assert( obj.prepared );
            
            values = obj.lookup_h_values( obj.ambient_id, material_id, temperatures );
            
        end
        
        
        function values = lookup_h_values( obj, first_material_id, second_material_id, temperatures )
            
            assert( obj.prepared );
            
            values = obj.convection_nd.lookup_values( first_material_id, second_material_id, temperatures );
            
        end
        
        
        function fe = get_feeding_effectivity( obj, melt_id )
            
            assert( obj.prepared );
            assert( ismember( melt_id, obj.melt_ids ) )
            
            fe = obj.materials( melt_id ).get_feeding_effectivity();
            
        end
        
        
        function temperature_nd = get_liquidus_temperature_nd( obj, melt_id )
            
            assert( obj.prepared );
            assert( obj.liquidus_temperatures_nd.isKey( melt_id ) );
            
            temperature_nd = obj.liquidus_temperatures_nd( melt_id );
            
        end
        
        
        function temperature = get_feeding_effectivity_temperature( obj, melt_id )
                        
            temperature = obj.dimensionalize_temperatures( ...
                obj.get_feeding_effectivity_temperature_nd( melt_id ) ...
                );
            
        end
        
        
        function temperature_nd = get_feeding_effectivity_temperature_nd( obj, melt_id )
            
            assert( obj.prepared );
            assert( obj.fe_temperatures_nd.isKey( melt_id ) );
            
            temperature_nd = obj.fe_temperatures_nd( melt_id );
            
        end
        
        
        function temperature_nd = get_solidus_temperature_nd( obj, melt_id )
            
            assert( obj.prepared );
            assert( obj.solidus_temperatures_nd.isKey( melt_id ) );
            
            temperature_nd = obj.solidus_temperatures_nd( melt_id );
            
        end
        
        
        function temperature_diffs = dimensionalize_temperature_diffs( obj, temperature_diffs_nd )
            
            assert( obj.prepared )
            
            temperature_diffs = temperature_diffs_nd;%obj.dimensionalize_temperatures( temperature_diffs_nd ) - obj.temperature_range( 1 );
            
        end
        
        
        function temperatures = dimensionalize_temperatures( obj, temperatures_nd )
            
            assert( obj.prepared );
            
            temperatures = temperatures_nd;%scale_temperatures( temperatures_nd, [ 0 1 ], obj.temperature_range );
            
        end
        
        
        function times = dimensionalize_times( obj, times_nd )
            
            assert( obj.prepared );
            
            times = times_nd * obj.time_factor;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        space_step
        max_length
        
        materials
        ambient_id
        melt_ids
        
        convection
        
        space_step_set
        max_length_set
        ambient_material_set
        
        prepared
        
        extremes
        time_factor_extremes
        temperature_range
        
        time_factor
        space_step_nd
        initial_temperatures_nd
        liquidus_temperatures_nd
        fe_temperatures_nd
        solidus_temperatures_nd
        material_properties_nd
        convection_nd
        
    end
    
    
    methods ( Access = private )
        
        function extremes = compute_extremes( obj )
            
            material_count = obj.materials.Count;
            keys = cell2mat( obj.materials.keys() );
            material_property_extremes = nan( material_count, Material.count() );
            for i = 1 : material_count
                
                if keys( i ) == obj.ambient_id; continue; end
                material = obj.materials( keys( i ) );
                material_property_extremes( i, : ) = material.get_extremes();
                
            end
            
            extreme_fns = obj.materials( keys( 1 ) ).get_extreme_fns();
            extremes = nan( Material.count(), 1 );
            for i = 1 : Material.count()
                
                fn = extreme_fns{ i };
                extremes( i ) = fn( material_property_extremes( :, i ) );
                
            end
            
%             k_compare = extremes( Material.K_INDEX );
%             h_compare = obj.convection.get_extreme() * obj.space_step;
%             if k_compare > h_compare
%                 extremes( Material.K_INDEX ) = k_compare;
%             else
%                 extremes( Material.K_INDEX ) = h_compare;
%             end
%             
            assert( ~any( isnan( extremes ) ) );
            
        end
        
        
        function temperature_range = compute_temperature_range( obj )
            
            material_count = obj.materials.Count;
            keys = cell2mat( obj.materials.keys() );
            its = zeros( material_count, 1 );
            for i = 1 : material_count
                
                its( i ) = obj.materials( keys( i ) ).get_initial_temperature();
                
            end
            temperature_range = [ min( its ) max( its ) ];
            
        end
        
        
        function material_properties_nd = prepare_properties( obj, material_nd )
            
            material_properties_nd( obj.Q_INDEX ) = material_nd.get( Material.CP_INDEX ).compute_q_property( [ 0 1 ] );
            rho_nd = material_nd.get( Material.RHO_INDEX );
            material_properties_nd( obj.RHO_INDEX ) = RhoProperty( rho_nd.temperatures, rho_nd.values );
            cp_nd = material_nd.get( Material.CP_INDEX );
            material_properties_nd( obj.CP_INDEX ) = CpProperty( cp_nd.temperatures, cp_nd.values );
            material_properties_nd( obj.K_INV_INDEX ) = material_nd.get( Material.K_INDEX ).compute_k_half_space_step_inverse_property( obj.space_step );
            
        end
        
        
        function initial_temperature = lookup_initial_temperatures_nd( obj, material_id )
            
            initial_temperature = obj.initial_temperatures_nd( material_id );
            
        end
        
    end
    
end

