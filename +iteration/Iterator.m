classdef Iterator < utils.Printer & handle
    
    % TODO make into interface
    
    properties ( Access = public )
        initial_time_step(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1.0
    end
    
    
    properties ( SetAccess = private )
        simulation_times(1,1) util.StepTracker
        computation_times(1,1) util.StepTracker
        solver_iterations(1,1) util.StepTracker
    end
    
    
    properties ( SetAccess = private, Dependent )
        count
    end
    
    
    methods % getters
        
        function value = get.count( obj )
            value = obj.simulation_times.count;
        end
        
    end
    
    
    methods ( Access = public )
        
        function iterate( obj )
            obj.meta_kernel.update_system();
            obj.iterate_impl();
            obj.simulation_times.append( obj.get_simulation_time() );
            obj.computation_times.append( obj.get_computation_time() );
            obj.solver_iterations.append( obj.get_solver_iteration_count() );
            obj.printf( obj.assemble_iteration_method() );
        end
        
    end
    
    
    properties ( Access = protected )
        meta_kernel(1,1)
    end
    
    
    methods ( Access = protected, Abstract )
        iterate_impl( obj );
        time = get_computation_time( obj );
        time = get_simulation_time( obj );
        count = get_solver_iteration_count( obj );
        message = get_message( obj );
    end
    
    
    methods ( Access = protected )
        
        function obj = Iterator( meta_kernel )
            obj.simulation_times = util.StepTracker();
            obj.computation_times = util.StepTracker();
            obj.solver_iterations = util.StepTracker();
            obj.meta_kernel = meta_kernel;
        end
        
        function set_time_step( obj, time_step )
            obj.time_step = time_step;
        end
        
        function message = assemble_iteration_method( obj )
            messages = [ ...
            	sprintf( "Step %i", obj.count ) ...
                sprintf( "CompTime %.2fs", obj.computation_times.values( end ) ) ...
                sprintf( "SimTime %.2fs", obj.simulation_times.values( end ) ) ...
                obj.get_message() ...
                ];
            message = strjoin( [ strjoin( messages, ", " ) newline ] );
        end
        
    end
    
end

