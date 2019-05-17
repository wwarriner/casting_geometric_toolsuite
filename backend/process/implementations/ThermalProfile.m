classdef ThermalProfile < Process
    
    properties ( Access = public )
        %% inputs
        mesh
        physical_properties
        
        %% outputs
        solidification_times
        thermal_modulus
        thermal_modulus_filtered
        thermal_modulus_filter_threshold
        
    end
    
    
    properties ( Access = public, Constant )
        
        MOLD_PAD_STL_UNITS = 'stl_units';
        MOLD_PAD_RATIO = 'ratio';
        MOLD_PAD_MESH_COUNT = 'count';
        
    end
    
    
    methods ( Access = public )
        
        function obj = ThermalProfile( varargin )
            
            obj = obj@Process( varargin{ : } );
            
        end
        
        
        function run( obj )
            
            % TODO options
            % FDM Solver needs its own entire optionset, maybe
            % probably have a separate options file, and have fdm read that
            % that option would include mold material, melt material, mold/melt
            % htc
            % AUTOMATE initial temperature somehow
            %   either direct user supply OR some multiple of liquidus (1.1?)
            %
            %
            % this method also needs options hooked up
            % FDM Mesh method (count, stl_units, ratio)
            
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
            end
            assert( ~isempty( obj.mesh ) );
            
            if ~isempty( obj.options )
                base = 'processes.thermal_profile';
                obj.mold_material_filename = obj.options.get( [ base '.mold_material' ] );
                obj.melt_material_filename = obj.options.get( [ base '.melt_material' ] );
                obj.mold_melt_convection_filename = obj.options.get( [ base '.mold_melt_convection' ] );
                FALLBACK_MELT_INITIAL_TEMPERATURE_C = nan;
                obj.melt_initial_temperature_c = obj.options.get( ...
                    [ base '.melt_initial_temperature_c' ], ...
                    FALLBACK_MELT_INITIAL_TEMPERATURE_C ...
                    );
                obj.mold_pad_type = obj.options.get( ...
                    [ base '.mold_pad_type' ], ...
                    obj.FALLBACK_MOLD_PAD_TYPE ...
                    );
                obj.mold_pad_amounts = obj.options.get( ...
                    [ base '.mold_pad_amounts' ], ...
                    obj.FALLBACK_MOLD_PAD_AMOUNTS ...
                    );
                obj.show_thermal_profile_dashboard = obj.options.get( ...
                    [ base '.show_dashboard' ], ...
                    obj.FALLBACK_SHOW_DASHBOARD ...
                    );
            end
            assert( ~isempty( obj.mold_material_filename ) );
            assert( ~isempty( obj.melt_material_filename ) );
            assert( ~isempty( obj.mold_melt_convection_filename ) );
            assert( ~isempty( obj.mold_pad_type ) );
            assert( ~isempty( obj.mold_pad_amounts ) );
            assert( ~isempty( obj.show_thermal_profile_dashboard ) );
            
            ambient_id = 0;
            mold_id = 1;
            melt_id = 2;
            
            space_step_in_m = obj.mesh.scale / 1000; % mm -> m
            pp = PhysicalProperties( space_step_in_m ); % mm -> m
            pp.add_ambient_material( AmbientMaterial( ambient_id ) );
            pp.add_material( MoldMaterial( mold_id, which( obj.mold_material_filename ) ) );
            melt = MeltMaterial( melt_id, which( obj.melt_material_filename ) );
            if ~isnan( obj.melt_initial_temperature_c )
                melt.set_initial_temperature( obj.melt_initial_temperature_c );
            end
            pp.add_melt_material( melt );
            
            conv = ConvectionProperties( ambient_id );
            conv.set_ambient( mold_id, generate_air_convection() );
            conv.set_ambient( melt_id, generate_air_convection() );
            conv.read( mold_id, melt_id, which( obj.mold_melt_convection_filename ) );
            pp.set_convection( conv );
            
            pp.prepare_for_solver();
            obj.physical_properties = pp;
            
            obj.printf( 'Computing thermal profile...\n' );
            
            switch obj.mold_pad_type
                case obj.MOLD_PAD_STL_UNITS
                    [ fdm_mesh, pad_count ] = obj.mesh.get_fdm_mesh_by_stl_units( ...
                        obj.mold_pad_amounts, ...
                        mold_id, ...
                        melt_id ...
                        );
                case obj.MOLD_PAD_RATIO
                    [ fdm_mesh, pad_count ] = obj.mesh.get_fdm_mesh_by_ratio( ...
                        obj.mold_pad_amounts, ...
                        mold_id, ...
                        melt_id ...
                        );
                case obj.MOLD_PAD_MESH_COUNT
                    [ fdm_mesh, pad_count ] = obj.mesh.get_fdm_mesh_by_count( ...
                        obj.mold_pad_amounts, ...
                        mold_id, ...
                        melt_id ...
                        );
                otherwise
                    assert( false );
            end
            
            solver = modeler.LinearSystemSolver();
            solver.set_tolerance( 1e-4 );
            solver.set_maximum_iterations( 100 );
            
            problem = SolidificationProblem( fdm_mesh, obj.physical_properties, solver );
            problem.set_implicitness( 1 );
            problem.set_latent_heat_target_ratio( 0.05 );
            
            iterator = modeler.QualityBisectionIterator( problem );
            iterator.set_maximum_iteration_count( 20 );
            iterator.set_quality_ratio_tolerance( 0.2 );
            iterator.set_time_step_stagnation_tolerance( 1e-2 );
            iterator.set_initial_time_step( obj.physical_properties.compute_initial_time_step() );
            iterator.set_printer( @fprintf );
            
            sol_temp = obj.physical_properties.get_fraction_solid_temperature( 1.0 );
            sol_time = SolidificationTimeResult( size( fdm_mesh ), sol_temp );
            results = containers.Map( ...
                { 'solidification_times' }, ...
                { sol_time } ...
                );
            
            manager = modeler.Manager( fdm_mesh, obj.physical_properties, solver, problem, iterator, results );
            if obj.show_thermal_profile_dashboard
                center = ceil( size( fdm_mesh ) );
                dashboard = SolidificationDashboard( fdm_mesh, obj.physical_properties, solver, problem, iterator, results, center );
                manager.set_dashboard( dashboard );
            end
            manager.solve();
            
            obj.solidification_times = obj.mesh.unpad_fdm_result( ...
                pad_count, ...
                solver.solidification_times.values ...
                );
            
            obj.thermal_modulus = sqrt( obj.solidification_times );
            max_mod = max( obj.thermal_modulus( : ) );
            min_mod = min( obj.thermal_modulus( obj.thermal_modulus( : ) > 0 ) );
            obj.thermal_modulus_filter_threshold = 0.01 * ( max_mod - min_mod );
            obj.thermal_modulus_filtered = max_mod .* imhmax( ...
                obj.thermal_modulus ./ max_mod, ...
                obj.thermal_modulus_filter_threshold ./ max_mod ...
                );
            
        end
        
        
        function legacy_run( ...
                obj, ...
                mesh, ...
                mold_material_filename, ...
                melt_material_filename, ...
                mold_melt_convection_filename ...
                )
            
            obj.mesh = mesh;
            obj.mold_material_filename = mold_material_filename;
            obj.melt_material_filename = melt_material_filename;
            obj.mold_melt_convection_filename = mold_melt_convection_filename;
            obj.mold_pad_type = obj.FALLBACK_MOLD_PAD_TYPE;
            obj.mold_pad_amounts = obj.FALLBACK_MOLD_PAD_AMOUNTS;
            obj.show_thermal_profile_dashboard = obj.FALLBACK_SHOW_THERMAL_PROFILE_DASHBOARD;
            obj.run();
            
        end
        
        
        function write( obj, title, common_writer )
            
            common_writer.write_array( title, obj.solidification_times );
            
        end
        
        
        function a = to_array( obj )
            
            a = obj.solidification_times;
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function name = NAME()
            
            name = mfilename( 'class' );
            
        end
        
    end
    
    
    methods ( Access = protected )
        
        function names = get_table_names( ~ )
            
            names = { ...
                };
            
        end
        
        
        function values = get_table_values( ~ )
            
            values = { ...
                };
            
        end
        
    end
    
    
    properties ( Access = private )
        
        mold_material_filename
        melt_material_filename
        mold_melt_convection_filename
        melt_initial_temperature_c
        mold_pad_type
        mold_pad_amounts
        show_thermal_profile_dashboard
        
    end
    
    
    properties ( Access = private, Constant )
        
        FALLBACK_MOLD_PAD_TYPE = 'ratio';
        FALLBACK_MOLD_PAD_AMOUNTS = 0.125;
        FALLBACK_SHOW_DASHBOARD = false;
        
    end
    
end

