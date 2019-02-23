classdef ThermalProfile < Process
    
    properties ( Access = public )
        %% inputs
        mesh
        physical_properties
        simulation_time_step_in_s
        
        %% outputs
        solidification_times
        
    end
    
    
    properties ( Access = public, Constant )
        
        NAME = 'thermal_profile'
        
    end
    
    
    methods ( Access = public )
        
        function obj = ThermalProfile( varargin )
            
            obj = obj@Process( varargin{ : } );
            
        end
        
        
        function run( obj )
            
            if ~isempty( obj.results )
                obj.mesh = obj.results.get( Mesh.NAME );
            end
            
            if ~isempty( obj.options )
                obj.physical_properties = obj.options.generate_physical_properties();
                obj.simulation_time_step_in_s = obj.options.simulation_time_step_in_s;
            end
            
            assert( ~isempty( obj.mesh ) );
            assert( ~isempty( obj.physical_properties ) );
            assert( ~isempty( obj.simulation_time_step_in_s ) );
            
            obj.printf( 'Computing thermal profile...\n' );
            
            ambient_id = 0;
            mold_id = 1;
            melt_id = 2;
            padding_in_mm = 25;
            fdm_mesh = obj.mesh.get_fdm_mesh( padding_in_mm, mold_id, melt_id );
            
            obj.physical_properties.set_space_step( obj.mesh.scale ./ 1000 ) % m
            obj.physical_properties.set_max_length( obj.mesh.shape  ); % count
            obj.physical_properties.prepare_for_solver();
            pp = obj.physical_properties;
            mg = MatrixGenerator( ...
                fdm_mesh, ...
                ambient_id, ...
                @pp.lookup_rho_cp_nd, ...
                @pp.lookup_k_nd_half_space_step_inv, ...
                @pp.lookup_h_nd ...
                );
            solver = Solver( fdm_mesh, obj.physical_properties, mg );
            solver.turn_printing_on();
            solver.turn_live_plotting_on();
            solver.solve( obj.simulation_time_step_in_s, melt_id );
            obj.solidification_times = solver.solidification_times;
            
        end
        
        
        function legacy_run( obj, mesh, physical_properties, simulation_time_step_in_s )
            
            obj.mesh = mesh;
            obj.physical_properties = physical_properties;
            obj.simulation_time_step_in_s = simulation_time_step_in_s;
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

