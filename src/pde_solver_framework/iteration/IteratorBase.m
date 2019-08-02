classdef IteratorBase < Printer & handle
    % @IteratorBase is a base class which should be extended to create
    % various types of time stepping iterators. The class is intended to
    % facilitate use of a pde problem by updating the system of equations, 
    % generating the next time step, and applying that time step
    % to the system of equations to update associated fields. Derived
    % classes may be used with @Looper to facilitate looping of iterations.
    %
    % NOTE: The constructor of @IteratorBase is protected. All derived
    % classes must assign a @ProblemInterface to @obj.problem before
    % iterating. The intended way to do this is via the derived class
    % constructor.
    
    properties
        initial_time_step(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1.0
    end
    
    properties ( SetAccess = private )
        simulation_times StepTracker
        computation_times StepTracker
        solver_iterations StepTracker
    end
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint32
        t(1,1) double {mustBeReal,mustBeFinite}
        t_prev(1,1) double {mustBeReal,mustBeFinite}
        dt(1,1) double {mustBeReal,mustBeFinite}
    end
    
    methods
        % @iterate updates the pde system, generates a new time step, and
        % applies it to the problem
        function iterate( obj )
            assert( isa( obj.problem, 'ProblemInterface' ) );
            
            obj.problem.prepare_system();
            obj.iterate_impl();
            obj.simulation_times.append( obj.get_simulation_time() );
            obj.computation_times.append( obj.get_computation_time() );
            obj.solver_iterations.append( obj.get_solver_iteration_count() );
            obj.printf( obj.assemble_iteration_method() );
        end
        
        function value = get.count( obj )
            value = obj.simulation_times.count;
        end
        
        function value = get.t( obj )
            value = double( obj.simulation_times.total );
        end
        
        function value = get.t_prev( obj )
            if obj.simulation_times.count <= 1
                value = 0;
            else
                value = double( obj.simulation_times.running_totals( end - 1 ) );
            end
        end
        
        function value = get.dt( obj )
            value = double( obj.simulation_times.values( end ) );
        end
    end
    
    properties ( Access = protected )
        problem % ProblemInterface
    end
    
    methods ( Abstract, Access = protected )
        % @iterate_impl is the user-implemented functionality for
        % generating the next time step and applying it to @obj.problem
        % using @obj.problem.solve.
        iterate_impl( obj );
        
        % @get_computation_time returns the time taken to run
        % @iterate_impl.
        % Outputs:
        % - time is a nonnegative scalar double
        time = get_computation_time( obj );
        
        % @get_simulation_time returns the time step determined by
        % @iterate_impl.
        % Outputs:
        % - time is a nonnegative scalar double
        time = get_simulation_time( obj );
        
        % @get_solver_iteration_count returns the number of iterations used
        % by the solver in @iterate_impl.
        % Outputs:
        % - count is a nonnegative scalar double
        count = get_solver_iteration_count( obj );
        
        % @get_message returns any human-readable information pertaining to
        % computations in @iterate_impl, which are then printed.
        % Outputs:
        % - message is a scalar string
        message = get_message( obj );
    end
    
    methods ( Access = protected )
        function obj = IteratorBase( problem )
            obj.simulation_times = StepTracker();
            obj.computation_times = StepTracker();
            obj.solver_iterations = StepTracker();
            obj.problem = problem;
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

