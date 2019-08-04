classdef ThermalProfile < Process
    % @GeometricProfile encapsulates the behavior and data of a geometric
    % approach to the solidification profile of castings.
    % Dependencies:
    % - @Mesh
    properties
        mold_material_file(1,1) string = "a356.txt"
        melt_material_file(1,1) string = "silica_dry.txt"
        mold_melt_h_file(1,1) string = "al_sand_htc.txt"
        melt_initial_temperature(1,1) double {mustBeReal,mustBeFinite} = 700 % C
        melt_feeding_effectivity(1,1) double {mustBeReal,mustBeFinite} = 0.3 % unitless
        ambient_temperature(1,1) double {mustBeReal,mustBeFinite} = 25 % C
        mold_pad_type(1,1) string = "ratio" % { ratio, length, count }
        mold_pad_amounts(1,:) double {mustBeReal,mustBeFinite} = 0.125
        ambient_h(1,1) double {mustBeReal,mustBeFinite} = 10 % W / m^2 * K
        time_step_mode(1,1) string = "bisection" % { bisection } TODO: add others
        latent_heat_quality_ratio(1,1) double = 0.1 % ( 0, inf ] smaller more accurate, larger faster
        % TODO: when changing settings class, invert dependency for
        % iteratorbase. Instead of current setup, pass it to
        % thermal_profile_query after setting it up.
    end
    
    properties ( SetAccess = private, Dependent )
        values(:,:,:) double
        values_interior(:,:,:) double
        filtered(:,:,:) double
        filtered_interior(:,:,:) double
        filter_amount(1,1) double
    end
    
    methods
        function obj = ThermalProfile( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function run( obj )
            obj.obtain_inputs();
            obj.prepare_thermal_profile_query()
        end
        
        function legacy_run( obj, mesh )
            obj.mesh = mesh;
            obj.run();
        end
        
        function write( obj, common_writer )
            common_writer.write_array( obj.NAME, obj.values, obj.mesh.spacing, obj.mesh.origin );
            %filter_title = strjoin( [ "filtered" obj.NAME ], "_" );
            %common_writer.write_array( filter_title, obj.filtered, obj.mesh.spacing, obj.mesh.origin );
        end
        
        function a = to_array( obj )
            a = obj.scaled;
        end
        
        function value = to_table( obj )
            value = list2table( ...
                { 'thickness_ratio' }, ...
                { obj.thickness_ratio } ...
                );
        end
        
        function value = get.values( obj )
            value = obj.unpad_get();
        end
        
        function value = get.values_interior( obj )
            value = obj.unpad_get( obj.mesh.interior );
        end
        
        function value = get.filtered( obj )
            value = obj.filter_profile_query.get();
        end
        
        function value = get.filtered_interior( obj )
            value = obj.filter_profile_query.get( obj.mesh.interior );
        end
        
        function value = get.filter_amount( obj )
            value = obj.compute_filter_profile_query_amount( obj.mesh.scale );
        end
    end
    
    methods ( Access = public, Static )
        function name = NAME()
            name = string( mfilename( 'class' ) );
        end
    end
    
    properties ( Access = private )
        mesh Mesh
        thermal_profile_query ThermalProfileQuery
        pad_count(1,:) uint32
    end
    
    methods ( Access = private )
        function obtain_inputs( obj )
            % TODO add full checks on values
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
            end
            assert( ~isempty( obj.mesh ) );
            
            if ~isempty( obj.options )
                loc = "processes.thermal_profile.mold_material";
                obj.mold_material_file = obj.options.get( loc );
            end
            assert( ~isempty( obj.mold_material_file ) );
            
            if ~isempty( obj.options )
                loc = "processes.thermal_profile.melt_material";
                obj.melt_material_file = obj.options.get( loc );
            end
            assert( ~isempty( obj.melt_material_file ) );
            
            if ~isempty( obj.options )
                loc = "processes.thermal_profile.mold_melt_h";
                obj.mold_melt_h_file = obj.options.get( loc );
            end
            assert( ~isempty( obj.mold_melt_h_file ) );
            
            if ~isempty( obj.options )
                loc = "processes.thermal_profile.melt_initial_temperature_c";
                obj.melt_initial_temperature = obj.options.get( loc );
            end
            assert( ~isempty( obj.melt_initial_temperature ) );
            
            if ~isempty( obj.options )
                loc = "processes.thermal_profile.melt_feeding_effectivity";
                obj.melt_feeding_effectivity = obj.options.get( loc );
            end
            assert( ~isempty( obj.melt_feeding_effectivity ) );
            
            if ~isempty( obj.options )
                loc = "processes.thermal_profile.ambient_temperature_c";
                obj.ambient_temperature = obj.options.get( loc );
            end
            assert( ~isempty( obj.ambient_temperature ) );
            
            if ~isempty( obj.options )
                loc = "processes.thermal_profile.mold_pad_type";
                obj.mold_pad_type = obj.options.get( loc );
            end
            assert( ~isempty( obj.mold_pad_type ) );
            
            if ~isempty( obj.options )
                loc = "processes.thermal_profile.mold_pad_amounts";
                obj.mold_pad_amounts = obj.options.get( loc );
            end
            assert( ~isempty( obj.mold_pad_amounts ) );
            
            if ~isempty( obj.options )
                loc = "processes.thermal_profile.ambient_h_w_per_m_k";
                obj.ambient_h = obj.options.get( loc );
            end
            assert( ~isempty( obj.ambient_h ) );
            
            if ~isempty( obj.options )
                loc = "processes.thermal_profile.time_step_mode";
                obj.time_step_mode = obj.options.get( loc );
            end
            assert( ~isempty( obj.time_step_mode ) );
            
            if ~isempty( obj.options )
                loc = "processes.thermal_profile.latent_heat_quality_ratio";
                obj.latent_heat_quality_ratio = obj.options.get( loc );
            end
            assert( ~isempty( obj.latent_heat_quality_ratio ) );
        end
        
        function prepare_thermal_profile_query( obj )
            obj.printf( "Computing thermal profile...\n" );
            pde_mesh = obj.prepare_pde_mesh();
            pp = obj.prepare_physical_properties();
            tpq = ThermalProfileQuery();
            tpq.latent_heat_quality_ratio = obj.latent_heat_quality_ratio;
            tpq.build( pde_mesh, pp, obj.MELT_ID );
            tpq.run();
            obj.thermal_profile_query = tpq;
        end
        
        function pde_mesh = prepare_pde_mesh( obj )
            obj.printf( "  Preparing PDE solver mesh...\n" );
            switch obj.mold_pad_type
                case "ratio"
                    [ pde_mesh, pad_count_out ] = obj.mesh.to_pde_mesh_by_ratio( obj.mold_pad_amounts, obj.MELT_ID, obj.MOLD_ID );
                case "length"
                    [ pde_mesh, pad_count_out ] = obj.mesh.to_pde_mesh_by_length( obj.mold_pad_amounts, obj.MELT_ID, obj.MOLD_ID );
                case "count"
                    pde_mesh = obj.mesh.to_pde_mesh_by_count( obj.mold_pad_amounts, obj.MELT_ID, obj.MOLD_ID );
                    pad_count_out = obj.mold_pad_amounts;
                otherwise
                    assert( false )
            end
            obj.pad_count = pad_count_out;
        end
        
        function pp = prepare_physical_properties( obj )
            obj.printf( "  Collecting physical properties...\n" );
            
            pp = PhysicalProperties();
            
            ambient = AmbientMaterial( obj.AMBIENT_ID );
            ambient.set_initial_temperature( obj.ambient_temperature );
            pp.add_ambient_material( ambient );
            
            mold = MoldMaterial( obj.MOLD_ID, which( obj.mold_material_file ) );
            mold.set_initial_temperature( obj.ambient_temperature );
            pp.add_material( mold );
            
            melt = MeltMaterial( obj.MELT_ID, which( obj.melt_material_file ) );
            melt.set_initial_temperature( obj.melt_initial_temperature );
            melt.set_feeding_effectivity( obj.melt_feeding_effectivity );
            pp.add_melt_material( melt );
            
            conv = ConvectionProperties( obj.AMBIENT_ID );
            conv.set_ambient( obj.MOLD_ID, HProperty( obj.ambient_h ) );
            conv.set_ambient( obj.MELT_ID, HProperty( obj.ambient_h ) );
            conv.read( obj.MOLD_ID, obj.MELT_ID, which( obj.mold_melt_h_file ) );
            pp.set_convection( conv );
            
            pp.prepare_for_solver();
        end
        
        function value = unpad_get( obj, varargin )
            value = obj.thermal_profile_query.get( varargin{ : } );
            start = obj.pad_count + 1;
            finish = uint32( size( value ) ) - start + 1;
            value = value( ...
                start( 1 ) : finish( 1 ), ...
                start( 2 ) : finish( 2 ), ...
                start( 3 ) : finish( 3 ) ...
                );
        end
    end
    
    properties ( Access = private, Constant )
        AMBIENT_ID uint32 = 0;
        MELT_ID uint32 = 1;
        MOLD_ID uint32 = 2;
    end
    
    methods ( Access = private, Static )
        function threshold = compute_filter_amount( mesh_scale )
            TOLERANCE = 1e-4;
            threshold = mesh_scale * ( 1 + TOLERANCE );
        end
    end
    
end

