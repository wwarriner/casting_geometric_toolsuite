classdef QualityBisectionIterator < iteration.IteratorBase
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
        maximum_iterations(1,1) uint64 {mustBePositive} = 100
        % @quality_tolerance controls how close quality must be to zero
        % before stopping.
        quality_tolerance(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 0.2
        % @stagnation_tolerance controls how close the current quality must
        % be to the previous quality before forcibly stopping computation.
        % Stagnation checking is required as there is no guarantee the
        % quality function is convex.
        stagnation_tolerance(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 0.01
    end
    
    properties ( SetAccess = private )
        qualities util.StepTracker
        bisection_iterations util.StepTracker
    end
    
    methods
        % Inputs:
        % - @problem is derived from @ProblemInterface, and must have a
        % public property @quality
        function obj = QualityBisectionIterator( problem )
            assert( isprop( problem, 'quality' ) );
            
            obj@iteration.IteratorBase( problem );
            obj.qualities = util.StepTracker();
            obj.bisection_iterations = util.StepTracker();
        end
    end
    
    methods ( Access = protected )
        function iterate_impl( obj )
            tic;
            obj.bisector = obj.create_bisector();
            obj.solver_counts = util.StepTracker();
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
        solver_counts util.StepTracker
        status_message(1,1) string
    end
    
    methods ( Access = private )
        function bisector = create_bisector( obj )
            LOWER_BOUND = 0;
            UPPER_BOUND = inf;
            TARGET_QUALITY = 0;
            bisector = util.BisectionTracker( ...
                obj.initial_time_step, ...
                LOWER_BOUND, ...
                UPPER_BOUND, ...
                @obj.update_quality, ...
                TARGET_QUALITY, ...
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
            elseif obj.is_finished()
                finished = true;
                message = obj.FINISHED_STATUS;
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
            below = false;
            %below = obj.problem.is_finished();
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

