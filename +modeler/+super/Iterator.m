classdef Iterator < utils.Printer & handle
    
    methods ( Access = public )
        
        function set_initial_time_step( obj, step )
            
            obj.initial_time_step = step;
            
        end
        
        
        function iterate( obj )
            
            assert( obj.is_ready() );
            
            tic;
            obj.problem.prepare();
            obj.iterate_impl();
            time = obj.problem.get_times().get_total();
            last_time = obj.computation_times.get_time( 1 );
            obj.computation_times.append_time_step( time - last_time );
            obj.iterations.append_time_step( obj.get_previous_iterations() );
            obj.solver_counts.append_time_step( obj.get_previous_solver_count() );
            obj.printf( obj.get_iteration_message() );
            
        end
        
        
        function count = get_step_count( obj )
            
            assert( obj.is_ready() );
            
            count = obj.simulation_times.get_count();
            
        end
        
        
        function total = get_elapsed_simulation_time( obj )
            
            total = obj.simulation_times.get_total_time();
            
        end
        
        
        function total = get_elapsed_computation_time( obj )
            
            total = obj.computation_times.get_total_time();
            
        end
        
        
        function total = get_total_iterations( obj )
            
            total = obj.iterations.get_total_time();
            
        end
        
        
        function total = get_total_solver_count( obj )
            
            total = obj.solver_counts.get_total_time();
            
        end
        
        
        function simulation_times = get_simulation_times( obj )
            
            assert( obj.is_ready() );
            
            simulation_times = obj.simulation_times;
            
        end
        
    end
    
    
    properties ( Access = protected )
        
        problem
        
    end
    
    
    methods ( Access = protected, Abstract )
        
        iterate_impl( obj );
        ready = is_ready_impl( obj );
        iterations = get_previous_iterations( obj );
        counts = get_previous_solver_count( obj );
        
    end
    
    
    methods ( Access = protected )
        
        function obj = Iterator( problem )
        
            assert( isa( problem, 'modeler.super.Problem' ) );
            
            obj.problem = problem;
            obj.computation_times = modeler.util.TimeTracker();
            obj.simulation_times = modeler.util.TimeTracker();
            obj.iterations = modeler.util.TimeTracker();
            obj.solver_counts = modeler.util.TimeTracker();
            obj.status = '';
        
        end
        
        
        function time_step = get_candidate_time_step( obj )
            
            assert( obj.is_ready() );
            
            if obj.simulation_times.get_count() == 0
                time_step = obj.initial_time_step;
            else
                time_step = obj.simulation_times.get_time_step();
            end
            
        end
        
        
        function append_time_step( obj, step )
            
            obj.simulation_times.append_time_step( step );
            
        end
        
        
        function set_status( obj, status )
            
            obj.status = status;
            
        end
        
        
        function msg = get_iteration_message( obj )
            
            msgs = { ...
            	sprintf( 'Step %i', obj.computation_times.get_count() ) ...
                sprintf( 'CompTime %.2fs', obj.computation_times.get_time( 1 ) ) ...
                sprintf( 'SimTime %.2fs', obj.simulation_times.get_time( 1 ) ) ...
                ...obj.problem.get_iteration_message(), ...
                obj.status ...
                };
            msg = [ strjoin( msgs, ', ' ) newline ];
            
        end
        
    end
    
    
    properties ( Access = private )
        
        initial_time_step
        
        computation_times
        simulation_times
        iterations
        solver_counts
        status
        
    end
    
    
    methods ( Access = private )
        
        function ready = is_ready( obj )
            
            ready = ~isempty( obj.simulation_times );
            ready = ready & ~isempty( obj.initial_time_step );
            ready = ready & obj.is_ready_impl();
            
        end
        
    end
    
end

