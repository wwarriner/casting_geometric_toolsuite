classdef QualityBisectionIterator < modeler.super.Iterator
    
    methods ( Access = public )
        
        function obj = QualityBisectionIterator( problem )
            
            obj@modeler.super.Iterator( problem );
            obj.maximum_iteration_count = 20;
            obj.quality_tolerance = 0.2;
            obj.stagnation_tolerance = 0.01;
            
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
        
    end
    
    
    methods ( Access = protected )
        
        function iterate_impl( obj )
            
            obj.per_iteration_solver_counts = modeler.util.TimeTracker();
            obj.bisector = obj.create_bisector();
            while true
                
                complete = obj.update( obj.bisector, obj.per_iteration_solver_counts );
                if complete; break; end
                
            end
            obj.append_time_step( obj.bisector.get() );
            
        end
        
        
        function ready = is_ready_impl( ~ )
            
            ready = true;
            
        end
        
        
        function iterations = get_previous_iterations( obj )
            
            iterations = obj.bisector.get_iterations();
            
        end
        
        
        function counts = get_previous_solver_count( obj )
            
            counts = obj.per_iteration_solver_counts.get_total_time();
            
        end
        
    end
    
    
    properties ( Access = private )
        
        maximum_iteration_count
        quality_tolerance
        stagnation_tolerance
        
        bisector
        per_iteration_solver_counts
        
    end
    
    
    properties ( Access = private, Constant )
        
        TOLERANCE_STATUS = 'Tolerance met.';
        ITERATION_STATUS = 'Exceeded maximum iterations.';
        STAGNATION_STATUS = 'Time step stagnated.';
        BELOW_CRITICAL_STATUS = 'Problem finished.';
        CONTINUING_STATUS = 'Continuing.';
        
    end
    
    
    methods ( Access = private )
        
        function bisector = create_bisector( obj )
            
            LOWER_BOUND = 0;
            UPPER_BOUND = inf;
            TARGET_QUALITY = 0;
            bisector = modeler.util.BisectionTracker( ...
                obj.get_candidate_time_step(), ...
                LOWER_BOUND, ...
                UPPER_BOUND, ...
                @(t)obj.problem.solve(t), ...
                TARGET_QUALITY, ...
                obj.quality_tolerance ...
                );
            
        end
        
        
        function complete = update( obj, bisector, solver_counts )
            
            within_tolerance = bisector.update();
            solver_counts.append_time_step( obj.problem.get_solver_count() );
            if within_tolerance
                complete = true;
                status = obj.TOLERANCE_STATUS;
            elseif obj.exceeded_maximum_iterations( bisector.get_iterations() )
                complete = true;
                status = obj.ITERATION_STATUS;
            elseif obj.stagnated( bisector.get(), bisector.get_previous() )
                complete = true;
                status = obj.STAGNATION_STATUS;
            elseif obj.is_finished()
                complete = true;
                status = obj.FINISHED_STATUS;
            else
                complete = false;
                status = obj.CONTINUING_STATUS;
            end
            obj.set_status( status );
            
        end
        
        
        function exceeded = exceeded_maximum_iterations( obj, iterations )
            
            exceeded = obj.maximum_iteration_count <= iterations;
            
        end
        
        
        function stagnated = stagnated( obj, current, previous )
            
            stagnated = ( abs( current - previous ) / previous ) < obj.stagnation_tolerance;
            
        end
        
        
        function below = is_finished( obj )
            
            below = obj.problem.is_finished();
            
        end
        
    end
    
end

