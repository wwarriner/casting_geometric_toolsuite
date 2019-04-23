classdef ThermalProfile < Process
    
    properties ( Access = public )
        %% inputs
        mesh
        physical_properties
        
        %% outputs
        solidification_times
        
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
                obj.physical_properties = obj.options.generate_physical_properties();
                obj.simulation_time_step_in_s = obj.options.simulation_time_step_in_s;
            end
            
            % TODO REMOVE
            ambient_id = 0;
            mold_id = 1;
            melt_id = 2;
            obj.physical_properties = generate_variable_test_properties( ...
                ambient_id, ...
                mold_id, ...
                melt_id, ...
                which( 'AlSi9.txt' ), ...
                obj.mesh.scale / 1000 ...
                );
            
            assert( ~isempty( obj.physical_properties ) );
            assert( obj.physical_properties.is_ready() );
            
            obj.printf( 'Computing thermal profile...\n' );
            
            padding_in_mm = 25;
            fdm_mesh = obj.mesh.get_fdm_mesh( padding_in_mm, mold_id, melt_id );
            
            obj.physical_properties.prepare_for_solver();
            lss = LinearSystemSolver( fdm_mesh, obj.physical_properties );
            solver = FdmSolver( fdm_mesh, obj.physical_properties, lss );
            solver.turn_printing_on( @obj.printf );
            solver.turn_live_plotting_on();
            solver.solve( melt_id );
            obj.solidification_times = solver.solidification_times;
            
        end
        
        
        function legacy_run( obj, mesh )
            
            obj.mesh = mesh;
            % add inputs for material spec files TBD
            obj.run();
            
        end
        
        
        function write( obj, title, common_writer )
            
            scaled_title = [ 'scaled_' title ];
            common_writer.write_array( scaled_title, obj.scaled_interior );
            filtered_title = [ 'filtered_' title ];
            common_writer.write_array( filtered_title, obj.filtered );
            common_writer.write_table( title, obj.to_table() );
            
        end
        
        
        function a = to_array( obj )
            
            a = obj.scaled_interior;
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function dependencies = get_dependencies()
            
            dependencies = { ...
                Mesh.NAME ...
                };
            
        end
        
        
        function name = NAME()
            
            name = mfilename( 'class' );
            
        end
        
    end
    
    
    methods ( Access = protected )
        
        function names = get_table_names( ~ )
            
            names = { ...
                'thickness_ratio' ...
                };
            
        end
        
        
        function values = get_table_values( obj )
            
            values = { ...
                obj.thickness_ratio ...
                };
            
        end
        
    end
    
end

