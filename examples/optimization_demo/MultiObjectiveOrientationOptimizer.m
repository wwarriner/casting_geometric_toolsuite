classdef (Sealed) MultiObjectiveOrientationOptimizer < OrientationOptimizer
    
    methods ( Access = public )
    
        function obj = MultiObjectiveOrientationOptimizer( ...
            component, ...
            feeders, ...
            element_count ...
            )
        
            obj = obj@OrientationOptimizer( ...
                component, ...
                feeders, ...
                element_count ...
                );

        end
    
    end
    
    
    methods ( Access = protected )
        
        function run_impl( obj )
            
            [ obj.minima, obj.function_values, obj.exitflag, obj.output ] ...
                = gamultiobj( obj.problem );
            
        end
        
        
        function solver = get_solver( ~ )
            
            solver = 'gamultiobj';
            
        end
        
        
        function solver_optimset_fn = get_solver_optimset_fn( ~ )
            
            solver_optimset_fn = @gamultiobj;
            
        end
        
    end
    
end

