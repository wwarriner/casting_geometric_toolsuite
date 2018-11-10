classdef (Sealed) SingleObjectiveOrientationOptimizer < OrientationOptimizer
    
    methods ( Access = public )
    
        function obj = SingleObjectiveOrientationOptimizer( ...
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
                = ga( obj.problem );
            
        end
        
        
        function solver = get_solver( ~ )
            
            solver = 'ga';
            
        end
        
        
        function solver_optimset_fn = get_solver_optimset_fn( ~ )
            
            solver_optimset_fn = @ga;
            
        end
        
    end
    
end

