classdef FdmSolver < handle
    
    properties ( GetAccess = public, SetAccess = private )
        
        iteration_count
        solver_count
        pcg_count
        computation_times
        simulation_time
        solidification_time
        
        temperature_initial
        temperature_final
        solidification_times
        
    end
    
    methods ( Access = public )
        
        function obj = FdmSolver( fdm_mesh, physical_properties, linear_system_solver )
            
            % INPUT ASSIGNMENT
            obj.mesh = fdm_mesh;
            obj.pp = physical_properties;
            obj.lss = linear_system_solver;
            
            % CONFIGURATION DEFAULTS
            obj.printing = false;
            obj.live_plotting = false;
            
        end
        
        
        function turn_printing_on( obj, printer )
            
            obj.printing = true;
            obj.printer = printer;
            
        end
        
        
        function turn_live_plotting_on( obj )
            
            obj.live_plotting = true;
            
        end
        
        
        function solve( obj, primary_melt_id )
            
            obj.setup_problem( primary_melt_id );
            while ~obj.is_finished()
                obj.iterate();
            end
            obj.postprocess();
            
        end
        
        
        function display_results( obj )
            
            volumeViewer( obj.temperature_final );
            volumeViewer( obj.solidification_times.values );
            
        end
        
        
        function display_computation_time_summary( obj )
            
            fh = figure();
            fh.Position = [ 50 50 300 800 ];
            axh = axes( fh );
            values = cell2mat( obj.computation_times.values() );
            values = values( : ).' ./ sum( values( : ) ) .* 100;
            nb = nan( size( values( : ).' ) );
            bb = [ values; nb ];
            bar( bb, 'stacked' );
            axh.XLim = [ 0.5 1.5 ];
            axh.YLim = [ 0 100 ];
            ytickformat( axh, '%g%%' );
            labels = obj.computation_times.keys();
            base_positions = cumsum( values );
            label_positions = base_positions - values ./ 2;
            for i = 1 : length( values )
                
                text( ...
                    axh.XTick( 1 ), label_positions( i ), ...
                    sprintf( '%s: %.2f%%', labels{ i }, values( i ) ), ...
                    'horizontalalignment', 'center', ...
                    'verticalalignment', 'middle' ...
                    );
                
            end
            
        end
        
        
        function print_summary( obj )
            
            obj.print( 'Iteration Count: %d\n', obj.iteration_count );
            obj.print( 'Solver Count: %d\n', obj.solver_count );
            obj.print( 'Approximate Computation Times: ' );
            obj.print( '%.2fs, ', obj.get_computation_times() );
            obj.print( '\n' );
            obj.print( 'Total Computation Time: %.2fs\n', obj.get_total_computation_time() );
            obj.print( 'Simulation Time: %.2fs\n', obj.simulation_time );
            obj.print( 'Solidification Time: %.2fs\n', obj.solidification_times.get_final_time() );
            
        end
        
    end
    
    
    properties ( Access = private )
        % INPUT
        mesh
        pp
        lss
        
        % CONFIGURATION
        printing
        live_plotting
        
        % PRIMARY MELT ID
        primary_melt_id
        
        % MESH
        shape
        element_count
        center
        bounding_box_lengths
        
        % TIMES
        time_step
        
        % TEMPERATURE
        u_prev
        u_curr
        
        dkdu
        
        melt_fe_temp
        
        % ENTHALPY
        q_prev
        
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
        
        function setup_problem( obj, primary_melt_id )
            % PRIMARY MELT ID
            obj.primary_melt_id = primary_melt_id;
            
            % MESH
            obj.shape = size( obj.mesh );
            obj.element_count = prod( obj.shape );
            obj.center = floor( ( obj.shape - 1 ) / 2 ) + 1;
            obj.bounding_box_lengths = padarray( obj.shape, 1, 0, 'pre' ) .* obj.pp.get_space_step();
            
            % COMPUTATION TIME
            obj.iteration_count = 0;
            obj.solver_count = 0;
            obj.pcg_count = 0;
            obj.computation_times = containers.Map( 'keytype', 'char', 'valuetype', 'double' );
            obj.simulation_time = 0;
            obj.solidification_time = 0;
            
            % SIMULATION TIME
            obj.simulation_time = 0;
            obj.update_simulation_time( 0 );
            obj.time_step = obj.pp.compute_initial_time_step( primary_melt_id );
            
            % TEMPERATURE
            u_init = obj.pp.generate_initial_temperature_field( obj.mesh );
            obj.temperature_initial = u_init;
            obj.u_prev = u_init;
            obj.u_curr = obj.u_prev;
            
            obj.melt_fe_temp = obj.pp.get_feeding_effectivity_temperature( primary_melt_id );
            
            % ENTHALPY FIELD
            obj.q_prev = obj.pp.compute_melt_enthalpies( obj.mesh, u_init );
            
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
            
        end
        
        
        function iterate( obj )
            
            [ u_candidate, q_candidate, time_step_candidate ] = ...
                obj.compute_next_temperature_field();
            obj.update_times( time_step_candidate );
            obj.update_fields( u_candidate, q_candidate );
            obj.update_results();
            
        end
        
        
        function postprocess( obj )
            
            obj.prepare_results();
            obj.update_dashboard();
            obj.print_summary();
            
        end
        
        
        function [ u_candidate, q_candidate, time_step ] = ...
                compute_next_temperature_field( obj )
            
            [ u_candidate, q_candidate, time_step, obj.dkdu ] = obj.lss.solve( ...
                obj.mesh, ...
                obj.q_prev, ...
                obj.u_prev, ...
                obj.u_curr, ...
                obj.time_step ...
                );
            
        end
        
        
        function update_times( obj, time_step )
            
            obj.update_iteration_count();
            obj.update_solver_count();
            obj.update_pcg_count();
            obj.computation_times = obj.update_times_map( ...
                obj.lss.get_last_times_map(), ...
                obj.computation_times ...
                );
            obj.update_simulation_time( time_step );
            
        end
        
        
        function update_fields( obj, u_candidate, q_candidate )
            
            obj.update_temperature_fields( u_candidate );
            obj.update_enthalpy_field( q_candidate );
            
        end
        
        
        function update_results( obj )
            
            obj.solidification_times.update( ...
                obj.mesh, ...
                obj.primary_melt_id, ...
                obj.pp, ...
                obj.u_prev, ...
                obj.u_curr, ...
                obj.simulation_time, ...
                obj.time_step ...
                );
            obj.update_dashboard();
            obj.print_update();
            
        end
        
        
        function update_iteration_count( obj )
            
            obj.iteration_count = obj.iteration_count + 1;
            
        end
        
        
        function update_solver_count( obj )
            
            obj.solver_count = obj.solver_count + obj.lss.get_last_solver_count();
            
        end
        
        
        function update_pcg_count( obj )
            
            obj.pcg_count = obj.pcg_count + obj.lss.get_last_pcg_count();
            
        end
        
        
        function update_simulation_time( obj, step )
            
            obj.time_step = step;
            obj.simulation_time = obj.simulation_time + obj.time_step;
            
        end
        
        
        function setup_dashboard( obj )
            
            if obj.live_plotting
                obj.dashboard = FdmDashboard( ...
                    obj.pp.get_temperature_range(), ...
                    obj.melt_fe_temp ...
                    );
                obj.dashboard.setup_temperature_profiles( ...
                    obj.bounding_box_lengths, ...
                    obj.shape, ...
                    obj.center, ...
                    obj.temperature_initial ...
                    );
                obj.dashboard.setup_time_temperature_curves( ...
                    obj.time_step, ...
                    obj.get_temperature_field_statistics( obj.temperature_initial, obj.primary_melt_id ), ...
                    obj.get_time_temperature_colors() ...
                    );
                obj.dashboard.setup_histogram( obj.DELTAU_HISTOGRAM, obj.element_count );
                obj.dashboard.setup_histogram( obj.DKDU_HISTOGRAM, obj.element_count );
                obj.dashboard.setup_labels( obj.get_labels(), obj.get_label_formatspecs(), obj.get_label_values() );
            end
            
        end
        
        
        function update_temperature_fields( obj, u_candidate )
            
            obj.u_prev = obj.u_curr;
            obj.u_curr = reshape( u_candidate, obj.shape );
            
        end
        
        
        function update_enthalpy_field( obj, q_candidate )
            
            obj.q_prev = q_candidate;
            
        end
        
        
        function update_dashboard( obj )
            
            if obj.live_plotting
                obj.dashboard.update_temperature_profiles( obj.u_curr );
                obj.dashboard.update_time_temperature_curves( ...
                    obj.simulation_time, ...
                    obj.get_temperature_field_statistics( obj.u_curr, obj.primary_melt_id ) ...
                    );
                obj.update_dashboard_histograms();
                obj.dashboard.update_labels( obj.get_label_values() );
            end
            
        end
        
        
        function update_dashboard_histograms( obj )
            
            delta_u = obj.u_curr - obj.u_prev;
            obj.dashboard.update_histogram( ...
                obj.DKDU_HISTOGRAM, ...
                obj.dkdu ./ delta_u( : ) ...
                );
            obj.dashboard.update_histogram( ...
                obj.DELTAU_HISTOGRAM, ...
                delta_u( : ) ...
                );
            
        end
        
        
        function labels = get_labels( obj )
            
            labels = obj.get_label_values( 'label' );
            
        end
        
        
        function formatspecs = get_label_formatspecs( obj )
            
            formatspecs = obj.get_label_values( 'formatspec' );
            
        end
        
        
        function values = get_label_values( obj, return_indicator )
            
            if nargin > 1 && strcmpi( return_indicator, 'label' )
                values = { ...
                    'Iteration count', ...
                    'Solver count', ...
                    'PCG count', ...
                    'Computation time (s)', ...
                    'Simulation time (s)', ...
                    'Solidification time (s)' ...
                    };
            elseif nargin > 1 && strcmpi( return_indicator, 'formatspec' )
                values = { ...
                    '%i', ...
                    '%i', ...
                    '%i', ...
                    '%.2f', ...
                    '%.2f', ...
                    '%.2f' ...
                    };
            else
                values = [ ...
                    obj.iteration_count ...
                    obj.solver_count ...
                    obj.pcg_count ...
                    sum( cell2mat( obj.computation_times.values() ) ) ...
                    obj.simulation_time, ...
                    obj.solidification_time ...
                    ];
            end
            
        end
        
        
        function print_update( obj )
            
            obj.print( 'Iteration %i: ', obj.iteration_count );
            obj.print( '%i solver steps, ', obj.lss.get_last_solver_count() );
            obj.print( '%.2fs sim time, ', obj.simulation_time );
            obj.print( '%.2fs comp time\n', obj.lss.get_last_total_time() );
            
        end
        
        
        function prepare_results( obj )
            
            obj.temperature_final = obj.u_curr;
            obj.solidification_time = obj.solidification_times.get_final_time();
            
        end
        
        
        function time = get_total_computation_time( obj )
            
            time = sum( obj.get_computation_times() );
            
        end
        
        
        function times = get_computation_times( obj )
            
            times = cell2mat( obj.computation_times.values() );
            
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
        
        function dest = update_times_map( source, dest )
            
            if isempty( dest )
                dest = containers.Map( source.keys(), source.values() );
            else
                keys = source.keys();
                for i = 1 : source.Count()
                    
                    key = keys{ i };
                    dest( key ) = dest( key ) + source( key );
                    
                end
            end
            
        end
        
    end
    
end

