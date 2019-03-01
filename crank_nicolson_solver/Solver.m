classdef Solver < handle
    
    properties ( GetAccess = public, SetAccess = private )
        
        iteration_count
        computation_time
        simulation_time
        
        temperature_initial
        temperature_final
        solidification_times
        
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
            
            obj.iteration_count = [];
            obj.computation_time = [];
            
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
            loop_count = 1;
            
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
                
                computation_times = [];
                
                %% DETERMINE TIME STEP
                generation_time = 0;
                while ~finished
                
                    RELAXATION_PARAMETER = 0.9;
                    [ m_L, m_R, r_L, r_R ] = obj.mg.generate( ...
                        obj.pp.get_ambient_temperature_nd(), ...
                        obj.pp.get_space_step_nd(), ...
                        simulation_time_step_next_nd, ...
                        u_2prev_nd, ...
                        u_prev_nd ...
                        );
                    
                    tic;
                    [ u_candidate_nd, ~, ~, ~, ~ ] = pcg( ...
                        m_L, ...
                        m_R * u_prev_nd( : ) + r_R - r_L, ...
                        obj.pcg_tol, ...
                        obj.pcg_max_it, ...
                        [], ...
                        [], ...
                        u_prev_nd( : ) ...
                        );
                    pcg_time = toc;
                    
                    q_candidate_nd = obj.pp.compute_melt_enthalpies_nd( obj.mesh, u_candidate_nd );
                    [ max_delta_q_nd, ind ] = max( q_prev_nd( : ) - q_candidate_nd( : ) );
                    %d_u = u_prev_nd( ind ) - u_candidate_nd( ind );
                    if max_delta_q_nd < obj.pp.get_min_latent_heat() / 2
                        simulation_time_step_next_nd = simulation_time_step_next_nd ./ RELAXATION_PARAMETER;
                        break;
                    else
                        simulation_time_step_next_nd = simulation_time_step_next_nd .* RELAXATION_PARAMETER;
                        if simulation_time_step_next_nd < 1e-12
                            assert( false );
                        end
                    end
                    
                    generation_time = generation_time + sum( obj.mg.get_last_times() ) + pcg_time;
                    
                end
                q_prev_nd = q_candidate_nd;
                computation_times( end + 1 ) = generation_time; %#ok<AGROW>
                
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
                computation_times( end + 1 ) = toc; %#ok<AGROW>
                
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
                
                if obj.printing
                    fprintf( 'Iteration %i: ', loop_count );
                    fprintf( '%.2fs, ', obj.pp.dimensionalize_times( simulation_time_nd ) );
                    fprintf( '%.2fs, ', computation_times );
                    fprintf( '\n' );
                end
                
                loop_count = loop_count + 1;
                u_2prev_nd = u_prev_nd;
                u_prev_nd = u_next_nd;
                obj.computation_time = obj.computation_time + sum( computation_times );
                
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
                fprintf( 'Approximate Computation Time: %.2f\n', obj.computation_time );
                fprintf( 'Simulation Time: %.2f\n', obj.simulation_time );
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

