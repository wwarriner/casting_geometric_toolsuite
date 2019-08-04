classdef QualityBisectionIterator < IteratorBase
    % @QualityBisectionIterator is a @IteratorBase which implements a
    % bisection method for finding an optimal time step quality. To do so,
    % @problem must have a public property @quality. The value of quality
    % must be zero when the time step is optimized. Negative quality
    % must indicate a larger time step is required, and positive quality
    % must indicate a smaller time step is required. It is recommended to
    % have quality a dimensionless ratio of some physical quantity for best
    % results.
    
    properties
        % @maximum_iterations controls how many bisection algorithm
        % iterations are allowed before forcibly stopping computation.
        maximum_iterations(1,1) uint32 {mustBePositive} = 100
        % @quality_target indirectly determines the time step used at each
        % step based on some fraction of latent heat. The larger this value
        % is, the longer the time step. The smaller, the more accurate the
        % solution is.Note the relationship between quality and time step
        % is highly non-linear, so it is recommended to use the default
        % value.
        quality_target(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 0.2
        % @quality_tolerance controls how close quality must be to
        % @quality_target before stopping.
        quality_tolerance(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 0.01
        % @stagnation_tolerance controls how close the current quality must
        % be to the previous quality before forcibly stopping computation.
        % Stagnation checking is required as there is no guarantee the
        % quality function is convex.
        stagnation_tolerance(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 0.01
    end
    
    properties ( SetAccess = private )
        qualities StepTracker
        bisection_iterations StepTracker
    end
    
    methods
        % Inputs:
        % - @problem is derived from @ProblemInterface, and must have a
        % public property @quality
        function obj = QualityBisectionIterator( problem )
            assert( isprop( problem, 'quality' ) );
            
            obj@IteratorBase( problem );
            obj.qualities = StepTracker();
            obj.bisection_iterations = StepTracker();
        end
    end
    
    methods ( Access = protected )
        function iterate_impl( obj )
            tic;
            obj.bisector = obj.create_bisector();
            obj.solver_counts = StepTracker();
            while ~obj.update( obj.bisector ); end
            obj.qualities.append( obj.bisector.y );
            obj.bisection_iterations.append( obj.bisector.count );
            obj.computation_time = toc;
        end
        
        function time = get_simulation_time( obj )
            time = obj.bisector.x;
        end
        
        function time = get_computation_time( obj )
            time = obj.computation_time;
        end
        
        function count = get_solver_iteration_count( obj )
            count = obj.solver_counts.total;
        end
        
        function message = get_message( obj )
            message = obj.status_message;
        end
    end
    
    properties ( Access = private )
        bisector BisectionTracker
        computation_time(1,1) double {mustBeReal,mustBeFinite,mustBeNonnegative} = 0.0
        solver_counts StepTracker
        status_message(1,1) string
    end
    
    methods ( Access = private )
        function bisector = create_bisector( obj )
            LOWER_BOUND = 0;
            UPPER_BOUND = inf;
            bisector = BisectionTracker( ...
                obj.get_starting_time_step(), ...
                LOWER_BOUND, ...
                UPPER_BOUND, ...
                @obj.update_quality, ...
                obj.quality_target, ...
                obj.quality_tolerance ...
                );
        end
        
        function quality = update_quality( obj, dt )
            obj.problem.solve( dt );
            quality = obj.problem.quality;
        end
        
        function finished = update( obj, bisector )
            if bisector.update()
                finished = true;
                message = obj.TOLERANCE_STATUS;
            elseif obj.exceeded_maximum_iterations( bisector.count )
                finished = true;
                message = obj.ITERATION_STATUS;
            elseif obj.stagnated( bisector.x, bisector.x_previous )
                finished = true;
                message = obj.STAGNATION_STATUS;
%             elseif obj.is_finished()
%                 finished = true;
%                 message = obj.FINISHED_STATUS;
            else
                finished = false;
                message = obj.CONTINUING_STATUS;
            end
            obj.status_message = message;
        end
        
        function exceeded = exceeded_maximum_iterations( obj, iterations )
            exceeded = obj.maximum_iterations <= iterations;
        end
        
        function stagnated = stagnated( obj, current, previous )
            change_ratio = abs( current - previous ) / previous;
            stagnated = change_ratio < obj.stagnation_tolerance;
        end
        
        function below = is_finished( obj )
            below = obj.problem.is_finished();
        end
        
        function step = get_starting_time_step( obj )
            if obj.simulation_times.count == 0
                step = obj.initial_time_step;
            else
                step = obj.dt;
            end
        end
    end
    
    properties ( Access = private, Constant )
        TOLERANCE_STATUS = "Tolerance met.";
        ITERATION_STATUS = "Exceeded maximum iterations.";
        STAGNATION_STATUS = "Time step stagnated.";
        FINISHED_STATUS = "Problem finished.";
        CONTINUING_STATUS = "Continuing.";
    end
    
end

