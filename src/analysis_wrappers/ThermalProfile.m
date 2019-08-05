classdef ThermalProfile < Process
    % @GeometricProfile encapsulates the behavior and data of a geometric
    % approach to the solidification profile of castings.
    % Settings:
    % - @ambient_h_w_per_m_sq_k, REQUIRED FINITE, convection coefficient with
    % ambient environment in units of W / m^2 * K.
    % - @ambient_temperature_c, REQUIRED FINITE, temperature of ambient
    % environment in units of C. Also used for mold temperature.
    % - @latent_heat_quality_ratio, ratio of latent heat to use when determining
    % quality of time steps. Lower values result in smaller time steps, which
    % requires more computational effort, longer computation time, and greater
    % accuracy.
    % - @latent_heat_quality_target, target quality value. Lower values,
    % including those below zero, result in smaller time steps, which requires
    % more computational effort, longer computation time, and greater accuracy.
    % - @melt_material_file, REQUIRED VALID MATERIAL DATA FILE, data file
    % containing temperature-property information for melt material.
    % - @melt_mold_h_file, REQUIRED VALID MATERIAL DATA FILE, data file
    % containing temperature-property information for convection coefficient
    % between melt and mold.
    % - @melt_feeding_effectivity, determines liquid fraction at which melt flow
    % ceases.
    % - @melt_initial_temperature_c, REQUIRED FINITE, temperature of melt in
    % units of C.
    % - @mold_material_file, REQUIRED VALID MATERIAL DATA FILE, data file
    % containing temperature-property information for mold material.
    % - @mold_pad_type, method for padding the casting envelope to create the
    % mold. Mesh is  otherwise unchanged. Options are "ratio", "length" and
    % "count". Ratio uses a fraction of the cavity envelope lengths. Length uses
    % a direct length value in casting length units. Count is an exact number of
    % mesh elements. Note that ratio and length are approximate due to integer
    % arithmetic.
    % - @mold_pad_amounts, amount of padding to use based on @mold_pad_type.
    % Must be scalar or vector of length 3. Must be double for "ratio" and
    % "length", or uint32 for "count".
    % - @time_step_mode, method for choosing time steps. Currently only
    % "bisection" is supported, which uses a fraction of the latent heat to
    % determine a quality value which informs a bisection algorithm in
    % choosing a time step.
    % Dependencies:
    % - @Mesh
    properties
        ambient_h_w_per_m_sq_k(1,1) double {mustBeReal,mustBePositive} = inf;
        ambient_temperature_c(1,1) double {mustBeReal} = inf;
        latent_heat_quality_ratio(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 0.1
        latent_heat_quality_target(1,1) double {mustBeReal,mustBeFinite} = 0.2
        melt_material_file(1,1) string = ""
        melt_mold_h_file(1,1) string = ""
        melt_feeding_effectivity(1,1) double {mustBeReal,mustBeFinite,mustBeBetween(melt_feeding_effectivity,0,1)} = 0.5
        melt_initial_temperature_c(1,1) double {mustBeReal,mustBeFinite}
        mold_material_file(1,1) string = ""
        mold_pad_type(1,1) string = "ratio" % { ratio, length, count }
        mold_pad_amounts(1,:) double {mustBeReal,mustBeFinite} = 0.125
        time_step_mode(1,1) string = "bisection" % { bisection } TODO: add others
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
    
    methods ( Access = protected )
        function check_settings( obj )
            assert( isfinite( obj.ambient_h_w_per_m_sq_k ) );
            assert( isfinite( obj.ambient_temperature_c ) );
            assert( obj.melt_material_file ~= "" );
            assert( obj.melt_mold_h_file ~= "" );
            assert( isfinite( obj.melt_initial_temperature_c ) );
            assert( obj.mold_material_file ~= "" );
            assert( ismember( obj.mold_pad_type, obj.MOLD_PAD_TYPE ) );
            assert( ismember( obj.time_step_mode, obj.TIME_STEP_MODE ) ); 
        end
        
        function update_dependencies( obj )
            mesh_key = ProcessKey( Mesh.NAME );
            obj.mesh = obj.results.get( mesh_key );
            
            assert( ~isempty( obj.mesh ) );
        end
    end
    
    properties ( Access = private )
        mesh Mesh
        thermal_profile_query ThermalProfileQuery
        pad_count(1,:) uint32
    end
    
    methods ( Access = private )
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
            ambient.set_initial_temperature( obj.ambient_temperature_c );
            pp.add_ambient_material( ambient );
            
            mold = MoldMaterial( obj.MOLD_ID, which( obj.mold_material_file ) );
            mold.set_initial_temperature( obj.ambient_temperature_c );
            pp.add_material( mold );
            
            melt = MeltMaterial( obj.MELT_ID, which( obj.melt_material_file ) );
            melt.set_initial_temperature( obj.melt_initial_temperature_c );
            melt.set_feeding_effectivity( obj.melt_feeding_effectivity );
            pp.add_melt_material( melt );
            
            conv = ConvectionProperties( obj.AMBIENT_ID );
            conv.set_ambient( obj.MOLD_ID, HProperty( obj.ambient_h_w_per_m_sq_k ) );
            conv.set_ambient( obj.MELT_ID, HProperty( obj.ambient_h_w_per_m_sq_k ) );
            conv.read( obj.MOLD_ID, obj.MELT_ID, which( obj.melt_mold_h_file ) );
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
        MOLD_PAD_TYPE = [ "ratio" "length" "count" ];
        TIME_STEP_MODE = [ "bisection" ];
    end
    
    methods ( Access = private, Static )
        function threshold = compute_filter_amount( mesh_scale )
            TOLERANCE = 1e-4;
            threshold = mesh_scale * ( 1 + TOLERANCE );
        end
    end
    
end

