classdef Solver < handle
    
    properties ( GetAccess = public, SetAccess = private )
        
        iteration_count
        computation_times
        simulation_time
        
        temperature_initial
        temperature_final
        solidification_times
        
    end
    
    methods ( Access = public )
        
        function obj = Solver( fdm_mesh, physical_properties, matrix_generator )
            % INPUT ASSIGNMENT
            obj.mesh = fdm_mesh;
            obj.pp = physical_properties;
            obj.mg = matrix_generator;
            
            % CONFIGURATION DEFAULTS
            obj.printing = false;
            obj.live_plotting = false;
            
            obj.pcg_tol = 1e-6;
            obj.pcg_max_it = 100;
            
            obj.max_iteration_count = 1000;
            
        end
        
        
        function turn_printing_on( obj, printer )
            
            obj.printing = true;
            obj.printer = printer;
            
        end
        
        
        function turn_live_plotting_on( obj )
            
            obj.live_plotting = true;
            
        end
        
        
        function solve( obj, starting_time_step_in_s, primary_melt_id )
            
            obj.setup_problem( starting_time_step_in_s, primary_melt_id );
            while ~obj.is_finished()
                obj.iterate();
            end
            obj.postprocess();
            
        end
        
    end
    
    
    properties ( Access = private )
        % INPUT
        mesh
        pp
        mg
        
        % CONFIGURATION
        printing
        live_plotting
        
        pcg_tol
        pcg_max_it
        
        max_iteration_count
        
        % PRIMARY MELT ID
        primary_melt_id
        
        % MESH
        shape
        element_count
        center
        bounding_box_lengths
        
        % TIMES
        simulation_time_nd
        time_step_nd
        
        % TEMPERATURE
        u_prev_nd
        u_curr_nd
        
        dkdu
        
        melt_fe_temp_nd
        
        % ENTHALPY
        q_prev_nd
        
        % RESULTS
        st
        
        % USER FEEDBACK
        printer
        dashboard
        
    end
    
    
    properties ( Access = private, Constant )
        
        DELTAU_HISTOGRAM = 1
        DKDU_HISTOGRAM = 2
        
    end
    
    
    methods ( Access = private )
        
        function setup_problem( obj, starting_time_step_in_s, primary_melt_id )
            % PRIMARY MELT ID
            obj.primary_melt_id = primary_melt_id;
            
            % MESH
            obj.shape = size( obj.mesh );
            obj.element_count = prod( obj.shape );
            obj.center = floor( ( obj.shape - 1 ) / 2 ) + 1;
            obj.bounding_box_lengths = padarray( obj.shape, 1, 0, 'pre' ) .* obj.pp.get_space_step();
            
            % COMPUTATION TIME
            obj.iteration_count = 0;
            obj.computation_times = zeros( 1, obj.mg.TIME_COUNT + 2 );
            
            % SIMULATION TIME
            obj.simulation_time_nd = 0;
            obj.update_simulation_time( 0 );
            obj.time_step_nd = obj.pp.nondimensionalize_times( starting_time_step_in_s );
            
            % TEMPERATURE
            u_initial_nd = obj.pp.generate_initial_temperature_field_nd( obj.mesh );
            obj.temperature_initial = obj.pp.dimensionalize_temperatures( u_initial_nd );
            obj.u_prev_nd = u_initial_nd;
            obj.u_curr_nd = obj.u_prev_nd;
            
            obj.melt_fe_temp_nd = obj.pp.get_feeding_effectivity_temperature_nd( primary_melt_id );
            
            % ENTHALPY FIELD
            obj.q_prev_nd = obj.pp.compute_melt_enthalpies_nd( obj.mesh, u_initial_nd );
            
            % RESULTS
            obj.solidification_times = SolidificationTime( obj.shape );
            
            % LIVE PLOTTING
            obj.setup_dashboard();
            
        end
        
        
        function finished = is_finished( obj )
            
            finished = false;
            
            % COMPLETELY SOLIDIFIED
            if obj.solidification_times.is_finished( obj.mesh, obj.primary_melt_id )
                obj.print( 'Fully Solidified\n' );
                finished = true;
            end
            
            % TOO MANY ITERATIONS
            if obj.iteration_count > obj.max_iteration_count
                finished = true;
            end
            
        end
        
        
        function iterate( obj )
            
            [ u_candidate_nd, q_candidate_nd, step_nd, iteration_times ] = ...
                obj.compute_next_temperature_field();
            obj.update_times( step_nd, iteration_times );
            obj.update_fields( u_candidate_nd, q_candidate_nd );
            obj.update_results( iteration_times );
            
        end
        
        
        function postprocess( obj )
            
            obj.prepare_results();
            obj.display_results();
            obj.print_summary();
            
        end
        
        
        function [ u_candidate_nd, q_candidate_nd, step_nd, iteration_times ] = ...
                compute_next_temperature_field( obj )
            
            time_step_range = [ 0 obj.time_step_nd inf ];
            iteration_times = zeros( 1, obj.mg.TIME_COUNT + 2 );
            while true
                
                [ lhs, rhs ] = obj.setup_system_of_equations( time_step_range( 2 ) );
                iteration_times( 1 : obj.mg.TIME_COUNT ) = ...
                    iteration_times( 1 : obj.mg.TIME_COUNT ) + ...
                    obj.mg.get_last_times();
                obj.update_dashboard_histograms();
                
                tic;
                u_candidate_nd = obj.solve_system_of_equations( lhs, rhs );
                iteration_times( obj.mg.TIME_COUNT + 1 ) = ...
                    iteration_times( obj.mg.TIME_COUNT + 1 ) + ...
                    toc;
                
                tic;
                q_candidate_nd = obj.pp.compute_melt_enthalpies_nd( obj.mesh, u_candidate_nd );
                quality_ratio = obj.determine_solution_quality_ratio( q_candidate_nd );
                iteration_times( obj.mg.TIME_COUNT + 2 ) = ...
                    iteration_times( obj.mg.TIME_COUNT + 2 ) + ...
                    toc;
                
                if obj.is_sufficient( quality_ratio )
                    step_nd = time_step_range( 2 );
                    break;
                end
                time_step_range = obj.choose_next_time_step_range( quality_ratio, time_step_range );
                
            end
            
        end
        
        
        function update_times( obj, step_nd, iteration_times )
            
            obj.update_iteration_count();
            obj.update_simulation_time( step_nd );
            obj.update_computation_times( iteration_times );
            
        end
        
        
        function update_fields( obj, u_candidate_nd, q_candidate_nd )
            
            obj.update_temperature_fields( u_candidate_nd );
            obj.update_enthalpy_field( q_candidate_nd );
            
        end
        
        
        function update_results( obj, iteration_times )
            
            obj.solidification_times.update_nd( ...
                obj.mesh, ...
                obj.primary_melt_id, ...
                obj.pp, ...
                obj.u_prev_nd, ...
                obj.u_curr_nd, ...
                obj.simulation_time_nd, ...
                obj.time_step_nd ...
                );
            obj.update_dashboard();
            obj.print_update( iteration_times );
            
        end
        
        
        function [ lhs, rhs ] = setup_system_of_equations( obj, candidate_step_nd )
            
            [ m_L, m_R, r_L, r_R, obj.dkdu ] = obj.mg.generate( ...
                obj.pp.get_ambient_temperature_nd(), ...
                obj.pp.get_space_step_nd(), ...
                candidate_step_nd, ...
                obj.u_prev_nd, ...
                obj.u_curr_nd ...
                );
            lhs = m_L;
            rhs = m_R * obj.u_curr_nd( : ) + r_R - r_L + obj.dkdu; 
            
        end
        
        
        function u_candidate_nd = solve_system_of_equations( obj, lhs, rhs )
            
            [ u_candidate_nd, ~, ~, ~, ~ ] = pcg( ...
                lhs, ...
                rhs, ...
                obj.pcg_tol, ...
                obj.pcg_max_it, ...
                [], ...
                [], ...
                obj.u_curr_nd( : ) ...
                );
            
        end
        
        
        function [ quality_ratio, q_candidate_nd ] = determine_solution_quality_ratio( obj, q_candidate_nd )
            
            max_delta_q_nd = max( obj.q_prev_nd( : ) - q_candidate_nd( : ) );
            LATENT_HEAT_FRACTION = 0.25;
            desired_q_nd = obj.pp.get_min_latent_heat() * LATENT_HEAT_FRACTION;
            quality_ratio = ( max_delta_q_nd - desired_q_nd ) / desired_q_nd;
            
        end
        
        
        function update_iteration_count( obj )
            
            obj.iteration_count = obj.iteration_count + 1;
            
        end
        
        
        function setup_dashboard( obj )
            
            if obj.live_plotting
                obj.dashboard = FdmDashboard( ...
                    obj.pp.get_temperature_range(), ...
                    obj.pp.dimensionalize_temperatures( obj.melt_fe_temp_nd ) ...
                    );
                obj.dashboard.setup_temperature_profiles( ...
                    obj.bounding_box_lengths, ...
                    obj.shape, ...
                    obj.center, ...
                    obj.temperature_initial ...
                    );
                obj.dashboard.setup_time_temperature_curves( ...
                    obj.pp.dimensionalize_times( obj.time_step_nd ), ...
                    obj.get_temperature_field_statistics( obj.temperature_initial, obj.primary_melt_id ), ...
                    obj.get_time_temperature_colors() ...
                    );
                obj.dashboard.setup_histogram( obj.DELTAU_HISTOGRAM, obj.element_count );
                obj.dashboard.setup_histogram( obj.DKDU_HISTOGRAM, obj.element_count );
            end
            
        end
        
        
        function update_temperature_fields( obj, u_candidate_nd )
            
            obj.u_prev_nd = obj.u_curr_nd;
            obj.u_curr_nd = reshape( u_candidate_nd, obj.shape );
            
        end
        
        
        function update_enthalpy_field( obj, q_candidate_nd )
            
            obj.q_prev_nd = q_candidate_nd;
            
        end
        
        
        function update_simulation_time( obj, step_nd )
            
            obj.time_step_nd = step_nd;
            obj.simulation_time_nd = obj.simulation_time_nd + obj.time_step_nd;
            obj.simulation_time = obj.pp.dimensionalize_times( obj.simulation_time_nd );
            
        end
        
        
        function update_computation_times( obj, iteration_times )
            
            obj.computation_times = obj.computation_times + iteration_times;
            
        end
        
        
        function update_dashboard( obj )
            
            if obj.live_plotting
                u_curr_d = obj.pp.dimensionalize_temperatures( obj.u_curr_nd );
                obj.dashboard.update_temperature_profiles( u_curr_d );
                obj.dashboard.update_time_temperature_curves( ...
                    obj.simulation_time, ...
                    obj.get_temperature_field_statistics( u_curr_d, obj.primary_melt_id ) ...
                    );
                obj.update_dashboard_histograms();
            end
            
        end
        
        
        function update_dashboard_histograms( obj )
            
            deltau = obj.pp.dimensionalize_temperature_diffs( obj.u_curr_nd - obj.u_prev_nd );
            obj.dashboard.update_histogram( ...
                obj.DKDU_HISTOGRAM, ...
                obj.pp.dimensionalize_temperature_diffs( obj.dkdu ) ./ deltau( : ) ...
                );
            obj.dashboard.update_histogram( ...
                obj.DELTAU_HISTOGRAM, ...
                deltau( : ) ...
                );
            
        end
        
        
        function print_update( obj, iteration_times )
            
            obj.print( 'Iteration %i: ', obj.iteration_count );
            obj.print( '%.2fs, ', obj.simulation_time );
            obj.print( '%.2fs, ', iteration_times );
            obj.print( '%.2fs\n', sum( iteration_times ) );
            
        end
        
        
        function prepare_results( obj )
            
            obj.temperature_final = obj.pp.dimensionalize_temperatures( obj.u_curr_nd );
            pp_temp = obj.pp;
            obj.solidification_times.manipulate( @pp_temp.dimensionalize_times );
            
        end
        
        
        function display_results( obj )
            
            if obj.live_plotting
                volumeViewer( obj.temperature_final );
                volumeViewer( obj.solidification_times.values );
            end
            
        end
        
        
        function print_summary( obj )
            
            obj.print( 'Iteration Count: %d\n', obj.iteration_count );
            obj.print( 'Approximate Computation Times: ' );
            obj.print( '%.2fs, ', obj.computation_times );
            obj.print( 'Total Computation Time: %.2fs\n', sum( obj.computation_times ) );
            obj.print( 'Simulation Time: %.2fs\n', obj.simulation_time );
            obj.print( 'Solidification Time: %.2fs\n', obj.solidification_times.get_final_time() );
            
        end
        
        
        function colors = get_time_temperature_colors( obj )
            
            colors = obj.get_temperature_field_statistics();
            
        end
        
        
        function values = get_temperature_field_statistics( obj, u, material_id )
            
            % colors
            COUNT = 3;
            if nargin == 1
                values = [ ...
                    0 0 1; ...
                    0 1 0; ...
                    1 0 0 ...
                    ];
                assert( size( values, 1 ) == COUNT );
            else
                values = [ ...
                    min( u( obj.mesh == material_id ) ), ...
                    mean( u( obj.mesh == material_id ) ), ...
                    max( u( obj.mesh == material_id ) ) ...
                    ];
                assert( numel( values ) == COUNT );
            end
            
        end
        
        
        function print( obj, varargin )
            
            if obj.printing
                obj.printer( varargin{ : } );
            end
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function sufficient = is_sufficient( quality_ratio )
            
            TOL = 0.01;
            sufficient = abs( quality_ratio ) < TOL;
            
        end
        
        
        function time_step_range = choose_next_time_step_range( quality_ratio, time_step_range )
            
            % todo find way to choose relaxation parameter based on gradient?
            RELAXATION_PARAMETER = 0.5;
            if 0 < quality_ratio
                time_step_range( 3 ) = time_step_range( 2 );
                interval = range( time_step_range );
                time_step_range( 2 ) = ( interval * RELAXATION_PARAMETER ) + time_step_range( 1 );
            else
                time_step_range( 1 ) = time_step_range( 2 );
                time_step_range( 2 ) = time_step_range( 2 ) / RELAXATION_PARAMETER;
            end
            
        end
        
    end
    
end

