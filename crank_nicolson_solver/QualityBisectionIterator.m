classdef QualityBisectionIterator < Iterator
    
    properties ( Access = public, Constant )
        
        TOLERANCE_REASON = 'Tolerance met.';
        ITERATION_REASON = 'Exceeded maximum iterations.';
        STAGNATION_REASON = 'Time step stagnated.';
        BELOW_CRITICAL_REASON = 'Solver field below critical value.';
        INCOMPLETE_REASON = 'Incomplete, continuing.';
        
    end
    
    
    methods ( Access = public )
        
        function obj = QualityBisectionIterator( solver )
            
            obj.solver = solver;
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
        
        
        function set_initial_time_step( obj, time_step )
            
            obj.time_step_previous = time_step;
            
        end
        
        
        function iterate( obj )
            
            assert( ~isempty( obj.time_step_previous ) );
            
            bisector = BisectionBounds( ...
                obj.time_step_previous, ...
                0, ...
                inf, ...
                @(t)obj.solver.get_quality_ratio(), ...
                0, ...
                obj.quality_tolerance ...
                );
            while true
                
                obj.solver.solve( bisector.get() );
                [ complete, reason ] = obj.is_complete( bisector );
                if complete
                    % print reason
                    break;
                end
                
            end
            obj.time_step_previous = bisector.get();
            
        end
        
        
        function time_step = get_previous_time_step( obj )
            
            time_step = obj.time_step_previous;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        solver
        
        maximum_iteration_count
        quality_tolerance
        stagnation_tolerance
        
        time_step_previous
        
    end
    
    
    methods ( Access = private )
        
        function [ complete, reason ] = is_complete( ...
                obj, ...
                bisector ...
                )
            
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
            
        end
        
        
        function exceeded = exceeded_maximum_iterations( obj, iterations )
            
            exceeded = obj.maximum_iteration_count <= iterations;
            
        end
        
        
        function stagnated = stagnated( obj, current, previous )
            
            stagnated = ( abs( current - previous ) / previous ) < obj.stagnation_tolerance;
            
        end
        
        
        function below = was_below_critical( obj )
            
            below = obj.solver.was_below_critical();
            
        end
        
    end
    
end

