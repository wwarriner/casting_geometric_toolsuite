classdef QualityBisectionIterator < iteration.Iterator
    
    properties ( Access = public )
        maximum_iterations(1,1) uint64 {mustBePositive} = 100
        quality_tolerance(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 0.2
        stagnation_tolerance(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 0.01
    end
    
    
    properties ( SetAccess = private )
        qualities(1,1) util.StepTracker
        bisection_iterations(1,1) util.StepTracker
    end
    
    
    methods ( Access = public )
        
        function obj = QualityBisectionIterator( problem )
            obj@iteration.Iterator( problem );
            obj.qualities = util.StepTracker();
            obj.bisection_iterations = util.StepTracker();
        end
        
    end
    
    
    methods ( Access = protected ) % abstract base class implementations
        
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
        bisector = []
        computation_time(1,1) double {mustBeReal,mustBeFinite,mustBeNonnegative} = 0.0
        solver_counts(1,1) util.StepTracker
        status_message(1,1) string
    end
    
    
    properties ( Access = private, Constant )
        TOLERANCE_STATUS = "Tolerance met.";
        ITERATION_STATUS = "Exceeded maximum iterations.";
        STAGNATION_STATUS = "Time step stagnated.";
        FINISHED_STATUS = "Problem finished.";
        CONTINUING_STATUS = "Continuing.";
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
            obj.problem.apply_time_step( dt );
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
    
end

