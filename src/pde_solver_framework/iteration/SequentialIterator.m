classdef SequentialIterator < IteratorBase
    
    methods
        % Inputs:
        % - @problem is derived from @ProblemInterface
        % - @sequence_fn is a @function_handle with signature dt = fn()
        % where dt is the current time step.
        function obj = SequentialIterator( problem, sequence )
            obj@IteratorBase( problem );
            obj.sequence = sequence;
        end
    end
    
    methods ( Access = protected )
        function iterate_impl( obj )
            dt = obj.sequence.next();
            assert( 0.0 < dt );
            
            t = tic;
            obj.problem.solve( dt );
            ctime = toc( t );
            
            obj.simulation_time = dt;
            obj.solver_count = 1;
            obj.computation_time = ctime;
        end
        
        function time = get_simulation_time( obj )
            time = obj.simulation_time;
        end
        
        function time = get_computation_time( obj )
            time = obj.computation_time;
        end
        
        function count = get_solver_iteration_count( obj )
            count = obj.solver_count;
        end
        
        function message = get_message( ~ )
            message = "";
        end
    end
    
    properties ( Access = private )
        sequence Sequence
        simulation_time(1,1) double {mustBeReal,mustBeFinite,mustBeNonnegative} = 0.0
        computation_time(1,1) double {mustBeReal,mustBeFinite,mustBeNonnegative} = 0.0
        solver_count(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1
    end
    
end

