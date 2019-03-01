classdef (Sealed) PhysicalProperties < handle
    
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
                material_nd = obj.materials( id ).nondimensionalize( obj.extremes, obj.temperature_range );
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
            
            convection_extreme = obj.extremes( Material.K_INDEX );
            obj.convection_nd = obj.convection.nondimensionalize( convection_extreme, obj.temperature_range );
            
            obj.time_factor = obj.extremes( Material.RHO_INDEX ) * ...
                obj.extremes( Material.CP_INDEX ) * ...
                obj.max_length ^ 2 / ...
                obj.extremes( Material.K_INDEX );

            obj.prepared = true;
            
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
        
        
        function latent_heat = get_min_latent_heat( obj )
            
            assert( obj.prepared );
            
            % use min over materials to be conservative
            latent_heat = inf;
            for id = 1 : obj.materials.Count
                
                if ismember( id, obj.melt_ids )
                    mp_nd = obj.material_properties_nd( id );
                    liquidus = mp_nd( obj.FS_INDEX ).get_liquidus();
                    solidus = mp_nd( obj.FS_INDEX ).get_solidus();
                    latent_heat = min( latent_heat, max( mp_nd( obj.Q_INDEX ).get_latent_heat( solidus, liquidus ) ) );
                end
                
            end
            assert( latent_heat ~= inf );
            
        end
        
        
        function q = compute_melt_enthalpies_nd( obj, mesh, temperatures )
            
            assert( obj.prepared );
            
            q = zeros( size( mesh ) );
            for id = 1 : obj.materials.Count
                
                if ismember( id, obj.melt_ids )
                    q( mesh == id ) = obj.lookup_q_nd( id, temperatures( mesh == id ) );
                end
                
            end
            
        end
        
        
        function values = lookup_rho_nd( obj, material_id, temperatures )
            
            assert( obj.prepared );
            
            mps = obj.material_properties_nd( material_id );
            values = mps( obj.RHO_INDEX ).lookup_values( temperatures );
            
        end
        
        
        function values = lookup_q_nd( obj, material_id, temperatures )
            
            assert( obj.prepared );
            
            mps = obj.material_properties_nd( material_id );
            values = mps( obj.Q_INDEX ).lookup_values( temperatures );
            
        end
        
        
        function values = lookup_rho_cp_nd( obj, material_id, temperatures )
            
            assert( obj.prepared );
            
            mps = obj.material_properties_nd( material_id );
            values = mps( obj.RHO_CP_INDEX ).lookup_values( temperatures );
            
        end
        
        
        function values = lookup_k_nd_half_space_step_inv( obj, material_id, temperatures )
            
            assert( obj.prepared );
            
            mps = obj.material_properties_nd( material_id );
            values = mps( obj.K_HALF_INV_INDEX ).lookup_values( temperatures );
            
        end
        
        
        function values = lookup_h_nd( obj, first_material_id, second_material_id, temperatures )
            
            assert( obj.prepared );
            
            values = obj.convection_nd.lookup_values( first_material_id, second_material_id, temperatures );
            
        end
        
        
        function values = lookup_fs_nd( obj, melt_id, temperatures )
            
            assert( obj.prepared );
            assert( ismember( melt_id, obj.melt_ids ) )
            
            mps = obj.material_properties_nd( melt_id );
            values = mps( obj.FS_INDEX ).lookup_values( temperatures );
            
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
        
        
        function temperatures = dimensionalize_temperatures( obj, temperatures_nd )
            
            assert( obj.prepared );
            
            temperatures = scale_temperatures( temperatures_nd, [ 0 1 ], obj.temperature_range );
            
        end
        
        
        function times = dimensionalize_times( obj, times_nd )
            
            assert( obj.prepared );
            
            times = times_nd * obj.time_factor;
            
        end
        
    end
    
    
    properties ( Access = private, Constant )
        
        RHO_CP_INDEX = 1;
        Q_INDEX = 2;
        RHO_INDEX = 3;
        CP_INDEX = 4;
        K_HALF_INV_INDEX = 5;
        FS_INDEX = 6;
        
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
            
            k_compare = extremes( Material.K_INDEX ) / obj.space_step;
            h_compare = obj.convection.get_extreme();
            if k_compare > h_compare
                extremes( Material.K_INDEX ) = k_compare * obj.space_step;
            else
                extremes( Material.K_INDEX ) = h_compare;
            end
            
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
            material_properties_nd( obj.RHO_CP_INDEX ) = RhoCpProperty( material_nd.get( Material.RHO_INDEX ), material_nd.get( Material.CP_INDEX ) );
            cp_nd = material_nd.get( Material.CP_INDEX );
            material_properties_nd( obj.CP_INDEX ) = CpProperty( cp_nd.temperatures, cp_nd.values );
            material_properties_nd( obj.K_HALF_INV_INDEX ) = KHalfSpaceStepInvProperty( material_nd.get( Material.K_INDEX ), obj.space_step );
            
        end
        
        
        function initial_temperature = lookup_initial_temperatures_nd( obj, material_id )
            
            initial_temperature = obj.initial_temperatures_nd( material_id );
            
        end
        
    end
    
end

