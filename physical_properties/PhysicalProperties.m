classdef (Sealed) PhysicalProperties < handle
    
    methods ( Access = public )
        
        function obj = PhysicalProperties()
            
            obj.space_step = [];
            obj.max_length = [];
            obj.ambient_temperature = [];
            
            obj.materials = containers.Map( 'KeyType', 'double', 'ValueType', 'any' );
            obj.melt_ids = [];
            
            obj.convection = ConvectionProperties.empty();
            
            obj.space_step_set = false;
            obj.max_length_set = false;
            obj.ambient_temperature_set = false;
            
            obj.prepared = false;
            
            obj.extremes = [];
            obj.temperature_range = [];
            
            obj.time_factor = [];
            obj.space_step_nd = [];
            obj.initial_temperatures_nd = containers.Map( 'KeyType', 'double', 'ValueType', 'any' );
            obj.material_properties_nd = containers.Map( 'KeyType', 'double', 'ValueType', 'any' );
            obj.fe_temperatures_nd = containers.Map( 'KeyType', 'double', 'ValueType', 'double' );
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
        
        
        % units are C
        function set_ambient_temperature( obj, ambient_temperature )
            
            assert( ~obj.prepared );
            
            assert( isscalar( ambient_temperature ) );
            assert( isa( ambient_temperature, 'double' ) );
            assert( isfinite( ambient_temperature ) );
            assert( 0 <= ambient_temperature );
            
            obj.ambient_temperature = ambient_temperature;
            obj.ambient_temperature_set = true;
            
        end
        
        
        function add_material( obj, material, id )
            
            assert( ~obj.prepared );
            
            assert( ~isa( material, 'MeltMaterial' ) );
            assert( material.is_ready() );
            assert( ~obj.materials.isKey( id ) );
            
            obj.materials( id ) = material;
            
        end
        
        
        function add_melt_material( obj, material, id )
            
            assert( ~obj.prepared );
            
            assert( isa( material, 'MeltMaterial' ) );
            assert( material.is_ready() );
            assert( ~obj.materials.isKey( id ) );
            
            obj.melt_ids( end + 1 ) = id;
            obj.materials( id ) = material;
            
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
            for i = 1 : obj.materials.Count
                
                ready = ready & obj.materials( i ).is_ready();
                
            end
            ready = ready & obj.convection.is_ready( cell2mat( obj.materials.keys() ) );
            ready = ready & obj.space_step_set;
            ready = ready & obj.max_length_set;
            ready = ready & obj.ambient_temperature_set;
            assert( ready );
            
            obj.space_step_nd = obj.space_step / obj.max_length;
            
            obj.extremes = obj.compute_extremes();
            obj.temperature_range = obj.get_temperature_range();
            ids = cell2mat( obj.materials.keys() );
            for i = 1 : obj.materials.Count
                
                id = ids( i );
                material_nd = obj.materials( id ).nondimensionalize( obj.extremes, obj.temperature_range );
                obj.initial_temperatures_nd( id ) = material_nd.get_initial_temperature();
                obj.material_properties_nd( id ) = obj.prepare_properties( material_nd );
                if ismember( id, obj.melt_ids )
                    obj.fe_temperatures_nd( id ) = material_nd.get_feeding_effectivity_temperature();
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
        
        
        function temperature_nd = get_feeding_effectivity_temperature_nd( obj, melt_id )
            
            assert( obj.prepared );
            assert( obj.fe_temperatures_nd.isKey( melt_id ) );
            
            temperature_nd = obj.fe_temperatures_nd( melt_id );
            
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
        K_HALF_INV_INDEX = 2;
        FS_INDEX = 3;
        
    end
    
    
    properties ( Access = private )
        
        space_step
        max_length
        ambient_temperature
        
        materials
        melt_ids
        
        convection
        
        space_step_set
        max_length_set
        ambient_temperature_set
        
        prepared
        
        extremes
        time_factor_extremes
        temperature_range
        
        time_factor
        space_step_nd
        initial_temperatures_nd
        fe_temperatures_nd
        material_properties_nd
        convection_nd
        
    end
    
    
    methods ( Access = private )
        
        function extremes = compute_extremes( obj )
            
            material_count = obj.materials.Count;
            keys = cell2mat( obj.materials.keys() );
            material_property_extremes = nan( material_count, Material.count() );
            for i = 1 : material_count
                
                material = obj.materials( keys( i ) );
                material_property_extremes( i, : ) = material.get_extremes();
                
            end
            
            extreme_fns = obj.materials( keys( 1 ) ).get_extreme_fns();
            extremes = zeros( Material.count(), 1 );
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
        
        
        function temperature_range = get_temperature_range( obj )
            
            material_count = obj.materials.Count;
            keys = cell2mat( obj.materials.keys() );
            its = zeros( material_count, 1 );
            for i = 1 : material_count
                
                its( i ) = obj.materials( keys( i ) ).get_initial_temperature();
                
            end
            temperature_range = [ min( its ) max( its ) ];
            
        end
        
        
        function material_properties_nd = prepare_properties( obj, material_nd )
            
            material_properties_nd( obj.RHO_CP_INDEX ) = RhoCpProperty( material_nd.get( Material.RHO_INDEX ), material_nd.get( Material.CP_INDEX ) );
            material_properties_nd( obj.K_HALF_INV_INDEX ) = KHalfSpaceStepInvProperty( material_nd.get( Material.K_INDEX ), obj.space_step );
            
        end
        
        
        function initial_temperature = lookup_initial_temperatures_nd( obj, material_id )
            
            initial_temperature = obj.initial_temperatures_nd( material_id );
            
        end
        
    end
    
end

