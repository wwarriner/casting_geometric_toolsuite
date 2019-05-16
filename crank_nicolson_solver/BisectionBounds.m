classdef (Sealed) BisectionBounds < handle
    
    methods ( Access = public )
        
        % -inf < x_lower
        % x_upper <= inf
        function obj = BisectionBounds( ...
                x_initial, ...
                x_lower, ...
                x_upper, ...
                compute_y_fn, ...
                y_target, ...
                tol ...
                )
            
            obj.x = x_initial;
            obj.lower = x_lower;
            obj.upper = x_upper;
            obj.compute_y_fn = compute_y_fn;
            obj.y_target = y_target;
            obj.iterations = 0;
            obj.tol = tol;
            
        end
        
        
        function x = get( obj )
            
            x = obj.x;
            
        end
        
        
        function x = get_previous( obj )
            
            x = obj.x_previous;
            
        end
        
        
        function iterations = get_iterations( obj )
            
            iterations = obj.iterations;
            
        end
        
        
        function within_tolerance = update( obj )
            
            y = obj.compute_y_fn( obj.x );
            within_tolerance = false;
            if obj.is_within_tolerance( y )
                within_tolerance = true;
                return;
            end
            
            if obj.is_below_target( y )
                obj.increase();
            else
                obj.decrease();
            end
                
            
        end
        
    end
    
    
    properties ( Access = private )
        
        x
        x_previous
        lower
        upper
        compute_y_fn
        y_target
        iterations
        tol
        
    end
    
    
    methods ( Access = private )
        
        function within = is_within_tolerance( obj, y )
            
            within = abs( y - obj.y_target ) <= obj.tol;
            
        end
        
        
        function below = is_below_target( obj, y )
            
            below = y < obj.y_target;
            
        end
        
        
        function increase( obj )
            
            obj.x_previous = obj.x;
            obj.lower = obj.x;
            if isinf( obj.upper )
                obj.x = obj.x * 2;
            else
                obj.x = mean( [ obj.lower obj.upper ] );
            end
            
        end
        
        
        function decrease( obj )
            
            obj.x_previous = obj.x;
            obj.upper = obj.x;
            obj.x = mean( [ obj.lower obj.upper ] );
            
        end
        
    end
    
end

