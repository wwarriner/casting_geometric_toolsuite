classdef ThermalProfile < Process
    % @GeometricProfile encapsulates the behavior and data of a geometric
    % approach to the solidification profile of castings.
    % Settings:
    % - @ambient_h_w_per_m_sq_k, REQUIRED FINITE, convection coefficient with
    % ambient environment in units of W / m^2 * K.
    % - @ambient_temperature_c, REQUIRED FINITE, temperature of ambient
    % environment in units of C. Also used for mold temperature.
    % - @filter_thermal_modulus_range_ratio, ratio for filtering thermal modulus
    % for downstream processing.
    % - @latent_heat_quality_target, target quality value. Lower values,
    % including those below zero, result in smaller time steps, which requires
    % more computational effort, longer computation time, and results in greater
    % accuracy.
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
        filter_thermal_modulus_range_ratio(1,1) double {...
            mustBeReal,...
            mustBeFinite,...
            mustBeGreaterThanOrEqual(filter_thermal_modulus_range_ratio,0),...
            mustBeLessThanOrEqual(filter_thermal_modulus_range_ratio,1)...
            } = 0.05
        latent_heat_quality_target(1,1) double {mustBeReal,mustBeFinite} = 0.2
        melt_material_file(1,1) string = ""
        melt_mold_h_file(1,1) string = ""
        melt_feeding_effectivity(1,1) double {...
            mustBeReal,...
            mustBeFinite,...
            mustBeGreaterThanOrEqual(melt_feeding_effectivity,0),...
            mustBeLessThanOrEqual(melt_feeding_effectivity,1)...
            } = 0.5
        melt_initial_temperature_c(1,1) double {mustBeReal,mustBeFinite}
        mold_material_file(1,1) string = ""
        mold_pad_type(1,1) string = "ratio" % { ratio, length, count }
        mold_pad_amounts(1,:) double {mustBeReal,mustBeFinite} = 0.125
        time_step_mode(1,1) string = "bisection" % { bisection } TODO: add others
        % TODO: when changing settings class, invert dependency for
        % iteratorbase. Instead of current setup, pass it to
        % thermal_profile_query after setting it up.
    end
    
    properties ( SetAccess = private )
        minimum_modulus(1,1) double {mustBeReal,mustBeFinite}
        maximum_modulus(1,1) double {mustBeReal,mustBeFinite}
        modulus_ratio(1,1) double {mustBeReal,mustBeFinite}
    end
    
    properties ( SetAccess = private, Dependent )
        values(:,:,:) double {mustBeReal,mustBeFinite}
        values_interior(:,:,:) double {mustBeReal,mustBeFinite}
        filtered(:,:,:) double {mustBeReal,mustBeFinite}
        filtered_interior(:,:,:) double {mustBeReal,mustBeFinite}
        filter_amount(1,1) double {mustBeReal,mustBeFinite}
        temperature(:,:,:) double {mustBeReal,mustBeFinite}
        temperature_interior(:,:,:) double {mustBeReal,mustBeFinite}
    end
    
    methods
        function obj = ThermalProfile( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function legacy_run( obj, mesh )
            obj.mesh = mesh;
            obj.run();
        end
        
        function write( obj, common_writer )
            common_writer.write_array( obj.NAME, obj.values, obj.mesh.spacing, obj.mesh.origin );
            filter_title = strjoin( [ "filtered" obj.NAME ], "_" );
            common_writer.write_array( filter_title, obj.filtered, obj.mesh.spacing, obj.mesh.origin );
            temperature_title = strjoin( [ "temperature" obj.NAME ], "_" );
            common_writer.write_array( temperature_title, obj.temperature, obj.mesh.spacing, obj.mesh.origin );
        end
        
        function a = to_array( obj )
            a = obj.scaled;
        end
        
        function value = get.values( obj )
            value = obj.get_profile();
        end
        
        function value = get.values_interior( obj )
            value = obj.get_profile( obj.mesh.interior );
        end
        
        function value = get.filtered( obj )
            value = obj.filtered_profile_query.get();
        end
        
        function value = get.filtered_interior( obj )
            value = obj.filtered_profile_query.get( obj.mesh.interior );
        end
        
        function value = get.filter_amount( obj )
            value = obj.compute_filter_amount( obj.values );
        end
        
        function value = get.temperature( obj )
            value = obj.get_temperature();
        end
        
        function value = get.temperature_interior( obj )
            value = obj.get_temperature( obj.mesh.interior );
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
        
        function run_impl( obj )
            obj.prepare_thermal_profile_query();
            obj.compute_statistics();
            obj.prepare_filtered_profile_query();
        end
        
        function value = to_table_impl( obj )
            value = list2table( ...
                { 'modulus_ratio' }, ...
                { obj.modulus_ratio } ...
                );
        end
    end
    
    properties ( Access = private )
        mesh Mesh
        pde_mesh % MeshInterface
        smp SolidificationMaterialProperties
        sip SolidificationInterfaceProperties
        thermal_profile_query ThermalProfileQuery
        filtered_profile_query FilteredProfileQuery
        pad_count(1,:) uint32
    end
    
    methods ( Access = private )
        function prepare_thermal_profile_query( obj )
            obj.printf( "Computing thermal profile...\n" );
            
            obj.prepare_pde_mesh();
            obj.prepare_properties();
            
            obj.printf( "  Solving...\n" );
            tpq = ThermalProfileQuery();
            tpq.quality_target = obj.latent_heat_quality_target;
            tpq.build( obj.pde_mesh, obj.smp, obj.sip, obj.MELT_ID );
            tpq.run();
            
            obj.thermal_profile_query = tpq;
        end
        
        function compute_statistics( obj )
            obj.printf( "  Computing statistics...\n" );
            [ obj.minimum_modulus, obj.maximum_modulus ] = ...
                obj.modulus_analysis( obj.values_interior );
            obj.modulus_ratio = ...
                1 - ( obj.minimum_modulus / obj.maximum_modulus );
        end
        
        function prepare_filtered_profile_query( obj )
            obj.printf( "  Filtering profile...\n" );
            obj.filtered_profile_query = FilteredProfileQuery( ...
                obj.values, ...
                obj.compute_filter_amount( obj.values ) ...
                );
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
            obj.pde_mesh = pde_mesh;
        end
        
        function prepare_properties( obj )
            obj.printf( "  Collecting physical properties...\n" );
            
            ambient = AmbientMaterial();
            ambient.id = obj.AMBIENT_ID;
            ambient.initial_temperature_c = obj.ambient_temperature_c;
            
            melt = MeltMaterial( which( obj.melt_material_file ) );
            melt.id = obj.MELT_ID;
            melt.initial_temperature_c = obj.melt_initial_temperature_c;
            melt.feeding_effectivity = obj.melt_feeding_effectivity;
            
            mold = MoldMaterial( which( obj.mold_material_file ) );
            mold.id = obj.MOLD_ID;
            mold.initial_temperature_c = obj.ambient_temperature_c;
            
            smp_in = SolidificationMaterialProperties();
            smp_in.add_ambient( ambient );
            smp_in.add_melt( melt );
            smp_in.add( mold );

            sip_in = SolidificationInterfaceProperties();
            sip_in.add_ambient( melt.id, HProperty( obj.ambient_h_w_per_m_sq_k ) );
            sip_in.add_ambient( mold.id, HProperty( obj.ambient_h_w_per_m_sq_k ) );
            sip_in.read( melt.id, mold.id, which( obj.melt_mold_h_file ) );
            
            obj.smp = smp_in;
            obj.sip = sip_in;
        end
        
        function value = get_profile( obj, mask_optional )
            if nargin < 2
                mask_optional = true( size( obj.mesh.interior ) );
            end
            mask_optional = obj.pad_mask( mask_optional );
            value = obj.thermal_profile_query.get_profile( mask_optional );
            value = obj.unpad( value );
        end
        
        function value = get_temperature( obj, mask_optional )
            if nargin < 2
                mask_optional = true( size( obj.mesh.interior ) );
            end
            mask_optional = obj.pad_mask( mask_optional );
            value = obj.thermal_profile_query.get_final_temperature( mask_optional );
            value = obj.unpad( value );
        end
        
        function value = pad_mask( obj, value )
            value = padarray( ...
                value, ...
                double( obj.pad_count ), ...
                true, ...
                'both' ...
                );
        end
        
        function value = unpad( obj, value )
            start = obj.pad_count + 1;
            finish = uint32( size( value ) ) - start + 1;
            value = value( ...
                start( 1 ) : finish( 1 ), ...
                start( 2 ) : finish( 2 ), ...
                start( 3 ) : finish( 3 ) ...
                );
        end
        
        function threshold = compute_filter_amount( obj, modulus )
            min_m = min( modulus( modulus > 0 ), [], 'all' );
            max_m = max( modulus, [], 'all' );
            range = max_m - min_m;
            threshold = obj.filter_thermal_modulus_range_ratio .* range;
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
        function [ minimum, maximum ] = modulus_analysis( value_interior )
            peaks = gray_peaks( value_interior );
            minimum = min( peaks );
            maximum = max( peaks );
        end
    end
    
end

