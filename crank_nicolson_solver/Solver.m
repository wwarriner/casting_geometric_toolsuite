classdef Solver < handle
    
    properties ( GetAccess = public, SetAccess = private )
        
        iteration_count
        computation_times
        simulation_time
        
        temperature_initial
        temperature_final
        solidification_times
        
        max_dkdu;
        max_melt_dkdu;
        max_liquid_melt_dkdu;
        
        min_dkdu;
        min_melt_dkdu;
        min_liquid_melt_dkdu;
        
    end
    
    methods ( Access = public )
        
        function obj = Solver( fdm_mesh, physical_properties, matrix_generator )
            
            obj.mesh = fdm_mesh;
            obj.pp = physical_properties;
            obj.mg = matrix_generator;
            
            obj.max_iteration_count = 1000;
            
            obj.printing = false;
            obj.live_plotting = false;
            
            obj.pcg_tol = 1e-6;
            obj.pcg_max_it = 100;
            
            obj.iteration_count = 0;
            obj.computation_times = zeros( 1, obj.mg.TIME_COUNT + 2 );
            
            obj.max_dkdu = -inf;
            obj.max_melt_dkdu = -inf;
            obj.max_liquid_melt_dkdu = -inf;
            
            obj.min_dkdu = inf;
            obj.min_melt_dkdu = inf;
            obj.min_liquid_melt_dkdu = inf;
            
        end
        
        
        function turn_printing_on( obj )
            
            obj.printing = true;
            
        end
        
        
        function turn_live_plotting_on( obj )
            
            obj.live_plotting = true;
            
        end
        
        
        function solve( obj, starting_time_step_in_s, primary_melt_id )
            
            u_initial_nd = obj.pp.generate_initial_temperature_field_nd( obj.mesh );
            obj.temperature_initial = obj.pp.dimensionalize_temperatures( u_initial_nd );
            u_prev_nd = u_initial_nd;
            u_2prev_nd = u_prev_nd;
            u_next_nd = u_prev_nd;
            
            q_prev_nd = obj.pp.compute_melt_enthalpies_nd( obj.mesh, u_initial_nd );
            
            shape = size( obj.mesh );
            element_count = prod( shape );
            st = SolidificationTime( shape );
            
            simulation_time_step_next_nd = obj.pp.nondimensionalize_times( starting_time_step_in_s );
            simulation_time_nd = 0;
            loop_count = 0;
            
            bounding_box_lengths = shape .* obj.pp.get_space_step();
            
            if obj.live_plotting
                center = floor( ( shape - 1 ) / 2 ) + 1;
                [ ~, axhs, phs ] = test_plot_setup( ...
                    obj.pp.get_temperature_range(), ...
                    bounding_box_lengths, ...
                    element_count ...
                    );
                
                melt_fe_temp_nd = obj.pp.get_feeding_effectivity_temperature_nd( primary_melt_id );
                melt_fe_temp = obj.pp.dimensionalize_temperatures( melt_fe_temp_nd );
                
                sim_time_d = obj.pp.dimensionalize_times( simulation_time_nd );
                u_next_d = obj.pp.dimensionalize_temperatures( u_next_nd );
                
                plot( axhs( 4 ), sim_time_d, min( u_next_d( obj.mesh( : ) == primary_melt_id ) ), 'b.' );
                plot( axhs( 4 ), sim_time_d, median( u_next_d( obj.mesh( : ) == primary_melt_id ) ), 'g.' );
                plot( axhs( 4 ), sim_time_d, max( u_next_d( obj.mesh( : ) == primary_melt_id ) ), 'r.' );
                axhs( 4 ).XLim = [ 0 starting_time_step_in_s ];
                horizontal_ph = draw_horizontal_lines( axhs( 4 ), melt_fe_temp, 'k', ':' );
                
                hist_h = [];
                
                draw_axial_plots_at_indices( axhs( 1 : 3 ), shape, bounding_box_lengths, obj.temperature_initial, center, 'k' );
                draw_horizontal_lines( axhs( 1 : 3 ), melt_fe_temp, 'k', ':' );
                drawnow();
            end
            
            finished = false;
            while ~finished
                %% END CONDITION
                if st.is_finished( obj.mesh, primary_melt_id )
                    if obj.printing
                        fprintf( 'Fully Solidified\n' );
                    end
                    break;
                end
                
                %% PRE UPDATE
                loop_count = loop_count + 1;
                
                %% DETERMINE TIME STEP
                iteration_times = zeros( 1, obj.mg.TIME_COUNT + 2 );
                while ~finished
                    
                    RELAXATION_PARAMETER = 0.9;
                    [ m_L, m_R, r_L, r_R, dkdu ] = obj.mg.generate( ...
                        obj.pp.get_ambient_temperature_nd(), ...
                        obj.pp.get_space_step_nd(), ...
                        simulation_time_step_next_nd, ...
                        u_2prev_nd, ...
                        u_prev_nd ...
                        );
                    
                    if obj.live_plotting
                        delete( hist_h );
                        hist_h = histogram( axhs( 5 ), obj.pp.dimensionalize_temperature_diffs( dkdu ), 51 );
                        axhs( 5 ).YLim = [ 1 element_count ];
                        axhs( 5 ).YScale = 'log';
                        drawnow();
                    end
                    
                    tic;
                    [ u_candidate_nd, ~, ~, ~, ~ ] = pcg( ...
                        m_L, ...
                        m_R * u_prev_nd( : ) + r_R - r_L + dkdu, ...
                        obj.pcg_tol, ...
                        obj.pcg_max_it, ...
                        [], ...
                        [], ...
                        u_prev_nd( : ) ...
                        );
                    pcg_time = toc;
                    
                    tic;
                    % TODO need a way to compute initial time step reasonably
                    % Need a way to make this more robust
                    q_candidate_nd = obj.pp.compute_melt_enthalpies_nd( obj.mesh, u_candidate_nd );
                    max_delta_q_nd = max( q_prev_nd( : ) - q_candidate_nd( : ) );
                    ratio = max_delta_q_nd / ( obj.pp.get_min_latent_heat() / 2 );
                    index = 1 - ratio; % positive means increase time step
                    TOL = 0.1;
                    if 0 < index
                        simulation_time_step_next_nd = simulation_time_step_next_nd ./ RELAXATION_PARAMETER;
                    else
                        simulation_time_step_next_nd = simulation_time_step_next_nd .* RELAXATION_PARAMETER;
                        if simulation_time_step_next_nd < 1e-12
                            assert( false );
                        end
                    end
                    enthalpy_time = toc;
                    
                    iteration_times( 1 : obj.mg.TIME_COUNT ) = iteration_times( 1 : obj.mg.TIME_COUNT ) + obj.mg.get_last_times();
                    iteration_times( obj.mg.TIME_COUNT + 1 ) = iteration_times( obj.mg.TIME_COUNT + 1 ) + pcg_time;
                    iteration_times( obj.mg.TIME_COUNT + 2 ) = iteration_times( obj.mg.TIME_COUNT + 2 ) + enthalpy_time;
                    
                    if abs( index ) < TOL
                        break;
                    end
                    
                end
                q_prev_nd = q_candidate_nd;
                
                obj.max_dkdu = max( max( dkdu ), obj.max_dkdu );
                obj.max_melt_dkdu = max( max( dkdu( obj.mesh == primary_melt_id ) ), obj.max_melt_dkdu );
                obj.max_liquid_melt_dkdu = max( max( dkdu( obj.mesh == primary_melt_id & u_prev_nd > melt_fe_temp_nd ) ), obj.max_liquid_melt_dkdu );
                
                obj.min_dkdu = min( min( dkdu ), obj.min_dkdu );
                obj.min_melt_dkdu = min( min( dkdu( obj.mesh == primary_melt_id ) ), obj.min_melt_dkdu );
                obj.min_liquid_melt_dkdu = min( min( dkdu( obj.mesh == primary_melt_id & u_prev_nd > melt_fe_temp_nd ) ), obj.min_liquid_melt_dkdu );
                
                simulation_time_nd = simulation_time_nd + simulation_time_step_next_nd;
                
                %% UPDATE RESULTS
                tic;
                u_next_nd = reshape( u_candidate_nd, shape );
                st.update_nd( ...
                    obj.mesh, ...
                    primary_melt_id, ...
                    obj.pp, ...
                    u_prev_nd, ...
                    u_next_nd, ...
                    simulation_time_nd, ...
                    simulation_time_step_next_nd ...
                    );
                
                %% PLOT
                if obj.live_plotting
                    delete( phs );
                    delete( horizontal_ph );
                    
                    sim_time_d = obj.pp.dimensionalize_times( simulation_time_nd );
                    u_next_d = obj.pp.dimensionalize_temperatures( u_next_nd );
                    
                    plot( axhs( 4 ), sim_time_d, min( u_next_d( obj.mesh( : ) == primary_melt_id ) ), 'b.' );
                    plot( axhs( 4 ), sim_time_d, median( u_next_d( obj.mesh( : ) == primary_melt_id ) ), 'g.' );
                    plot( axhs( 4 ), sim_time_d, max( u_next_d( obj.mesh( : ) == primary_melt_id ) ), 'r.' );
                    axhs( 4 ).XLim = [ 0 sim_time_d ];
                    horizontal_ph = draw_horizontal_lines( axhs( 4 ), melt_fe_temp, 'k', ':' );
                    
                    phs = draw_axial_plots_at_indices( axhs( 1 : 3 ), shape, bounding_box_lengths, u_next_d, center, 'r' );
                    drawnow();
                end
                
                %% PRINT
                if obj.printing
                    fprintf( 'Iteration %i: ', loop_count );
                    fprintf( '%.2fs, ', obj.pp.dimensionalize_times( simulation_time_nd ) );
                    fprintf( '%.2fs, ', iteration_times );
                    fprintf( '%.2fs\n', sum( iteration_times ) );
                end
                
                %% POST UPDATE
                u_2prev_nd = u_prev_nd;
                u_prev_nd = u_next_nd;
                obj.computation_times = obj.computation_times + iteration_times;
                
            end
            
            obj.iteration_count = loop_count;
            obj.simulation_time = obj.pp.dimensionalize_times( simulation_time_nd );
            obj.temperature_final = obj.pp.dimensionalize_temperatures( u_next_nd );
            obj.solidification_times = obj.pp.dimensionalize_times( st.values );

            if obj.live_plotting
                figure();
                axhs( 1 ) = subplot( 3, 1, 1 );
                axhs( 2 ) = subplot( 3, 1, 2 );
                axhs( 3 ) = subplot( 3, 1, 3 );
                draw_axial_plots_at_indices( axhs( 1 : 3 ), shape, bounding_box_lengths, obj.solidification_times, center, 'k' );
            end
            
            if obj.printing
                fprintf( 'Iteration Count: %d\n', obj.iteration_count );
                fprintf( 'Approximate Computation Times: ' );
                fprintf( '%.2fs, ', obj.computation_times );
                fprintf( 'Total Computation Time: %.2fs\n', sum( obj.computation_times ) );
                fprintf( 'Simulation Time: %.2fs\n', obj.simulation_time );
                fprintf( 'Max DKDU: %.2ek\n', obj.pp.dimensionalize_temperature_diffs( obj.max_dkdu ) );
                fprintf( 'Max Melt DKDU: %.2ek\n', obj.pp.dimensionalize_temperature_diffs( obj.max_melt_dkdu ) );
                fprintf( 'Max Liquid Melt DKDU: %.2ek\n', obj.pp.dimensionalize_temperature_diffs( obj.max_liquid_melt_dkdu ) );
                fprintf( 'Min DKDU: %.2ek\n', obj.pp.dimensionalize_temperature_diffs( obj.min_dkdu ) );
                fprintf( 'Min Melt DKDU: %.2ek\n', obj.pp.dimensionalize_temperature_diffs( obj.min_melt_dkdu ) );
                fprintf( 'Min Liquid Melt DKDU: %.2ek\n', obj.pp.dimensionalize_temperature_diffs( obj.min_liquid_melt_dkdu ) );
            end
            
        end
        
    end
    
    
    properties ( Access = private )
        
        mesh
        pp
        mg
        
        max_iteration_count
        
        printing
        live_plotting
        
        pcg_tol
        pcg_max_it
        
    end
    
end

