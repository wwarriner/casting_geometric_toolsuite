classdef QualityBisectionIterator < Iterator
    
    properties ( Access = public, Constant )
        
        TOLERANCE_REASON = 'Tolerance met.';
        ITERATION_REASON = 'Exceeded maximum iterations.';
        STAGNATION_REASON = 'Time step stagnated.';
        BELOW_CRITICAL_REASON = 'Solver field below critical value.';
        INCOMPLETE_REASON = 'Incomplete, continuing.';
        
    end
    
    
    methods ( Access = public )
        
        function obj = QualityBisectionIterator( problem )
            
            obj.problem = problem;
            obj.maximum_iteration_count = 20;
            obj.quality_tolerance = 0.2;
            obj.stagnation_tolerance = 0.01;
            
            obj.times = [];
            
        end
        
        
        function set_maximum_iteration_count( obj, count )
            
            assert( isscalar( count ) );
            assert( isa( count, 'double' ) );
            assert( 0 < count );
            
            obj.maximum_iteration_count = count;
            
        end
        
        
        function set_quality_ratio_tolerance( obj, tol )
            
            assert( isscalar( tol ) );
            assert( isa( tol, 'double' ) );
            assert( 0 < tol );
            
            obj.quality_tolerance = tol;
            
        end
        
        
        function set_time_step_stagnation_tolerance( obj, tol )
            
            assert( isscalar( tol ) );
            assert( isa( tol, 'double' ) );
            assert( 0 < tol );
            
            obj.stagnation_tolerance = tol;
            
        end
        
        
        function set_initial_time_step( obj, step )
            
            assert( isempty( obj.times ) );
            
            obj.times = TimeTracker( step );
            
        end
        
        
        function iterate( obj )
            
            assert( obj.is_ready() );
            
            bisector = obj.create_bisector();
            while true
                
                complete = obj.update( bisector );
                if complete; break; end
                
            end
            obj.times.append_time_step( bisector.get() );
            
        end
        
        
        function time_step = get_previous_time_step( obj )
            
            time_step = obj.times.get_time_step();
            
        end
        
        
        function times = get_times( obj )
            
            times = obj.times;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        problem
        
        maximum_iteration_count
        quality_tolerance
        stagnation_tolerance
        
        times
        reason_previous
        
    end
    
    
    methods ( Access = private )
        
        function ready = is_ready( obj )
            
            ready = ~isempty( obj.times );
            
        end
        
        
        function bisector = create_bisector( obj )
            
            LOWER_BOUND = 0;
            UPPER_BOUND = inf;
            TARGET_QUALITY = 0;
            bisector = BisectionTracker( ...
                obj.get_previous_time_step(), ...
                LOWER_BOUND, ...
                UPPER_BOUND, ...
                @(t)obj.problem.solve(t), ...
                TARGET_QUALITY, ...
                obj.quality_tolerance ...
                );
            
        end
        
        
        function complete = update( obj, bisector )
            
            within_tolerance = bisector.update();
            if within_tolerance
                complete = true;
                reason = obj.TOLERANCE_REASON;
            elseif obj.exceeded_maximum_iterations( bisector.get_iterations() )
                complete = true;
                reason = obj.ITERATION_REASON;
            elseif obj.stagnated( bisector.get(), bisector.get_previous() )
                complete = true;
                reason = obj.STAGNATION_REASON;
            elseif obj.was_below_critical()
                complete = true;
                reason = obj.BELOW_CRITICAL_REASON;
            else
                complete = false;
                reason = obj.INCOMPLETE_REASON;
            end
            obj.reason_previous = reason;
            
        end
        
        
        function exceeded = exceeded_maximum_iterations( obj, iterations )
            
            exceeded = obj.maximum_iteration_count <= iterations;
            
        end
        
        
        function stagnated = stagnated( obj, current, previous )
            
            stagnated = ( abs( current - previous ) / previous ) < obj.stagnation_tolerance;
            
        end
        
        
        function below = was_below_critical( obj )
            
            below = obj.problem.was_below_critical();
            
        end
        
    end
    
end

