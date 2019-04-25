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
    
    
    methods ( Access = public )
        
        function obj = ThermalProfile( varargin )
            
            obj = obj@Process( varargin{ : } );
            
        end
        
        
        function run( obj )
            
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
            end
            assert( ~isempty( obj.mesh ) );
            
            if ~isempty( obj.options )
                %obj.physical_properties = obj.options.generate_physical_properties();
            end
            
            % TODO REMOVE
            ambient_id = 0;
            mold_id = 1;
            melt_id = 2;
            
            pp = PhysicalProperties( obj.mesh.scale / 1000 ); % mm -> m
            pp.add_ambient_material( generate_air_properties( ambient_id ) );
            pp.add_material( read_mold_material( mold_id, which( 'silica_dry.txt' ) ) );
            melt = read_melt_material( melt_id, which( 'cf3mn.txt' ) );
            melt.set_initial_temperature( 1600 );
            melt.set_feeding_effectivity( 0.3 );
            pp.add_melt_material( melt );

            conv = ConvectionProperties( ambient_id );
            conv.set_ambient( mold_id, generate_air_convection() );
            conv.set_ambient( melt_id, generate_air_convection() );
            conv.set( mold_id, melt_id, read_convection( which( 'steel_sand_htc.txt' ) ) );
            pp.set_convection( conv );
            
            obj.physical_properties = pp;
            
            % KEEP
            assert( ~isempty( obj.physical_properties ) );
            assert( obj.physical_properties.is_ready() );
            
            obj.printf( 'Computing thermal profile...\n' );
            
            padding_in_mm = 25;
            fdm_mesh = obj.mesh.get_fdm_mesh( padding_in_mm, mold_id, melt_id );
            
            obj.physical_properties.prepare_for_solver();
            lss = LinearSystemSolver( fdm_mesh, obj.physical_properties );
            lss.set_implicitness( 1 );
            lss.set_solver_tolerance( 1e-4 );
            lss.set_solver_max_iteration_count( 100 );
            lss.set_latent_heat_target_fraction( 1.0 );
            lss.set_quality_ratio_tolerance( 0.2 );

            solver = FdmSolver( fdm_mesh, obj.physical_properties, lss );
            solver.turn_printing_on( @obj.printf );
            %solver.turn_live_plotting_on();
            solver.solve( melt_id );
            obj.solidification_times = obj.mesh.unpad_fdm_result( ...
                padding_in_mm, ...
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
        
        
        function legacy_run( obj, mesh )
            
            obj.mesh = mesh;
            % add inputs for material spec files TBD
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
        
        
        function values = get_table_values( obj )
            
            values = { ...
                };
            
        end
        
    end
    
end

