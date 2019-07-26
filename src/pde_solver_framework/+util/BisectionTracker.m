classdef (Sealed) BisectionTracker < handle
    
    properties ( SetAccess = private )
        x_values util.StepTracker
        y_values util.StepTracker
    end
    
    
    properties ( SetAccess = private, Dependent )
        x
        y
        x_previous
        count
    end
    
    
    methods ( Access = public )
        
        % -inf < x_lower
        % x_upper <= inf
        function obj = BisectionTracker( ...
                x_initial, ...
                x_lower, ...
                x_upper, ...
                compute_y_fn, ...
                y_target, ...
                tol ...
                )
            obj.x_values = util.StepTracker();
            obj.x_values.append( x_initial );
            obj.lower = x_lower;
            obj.upper = x_upper;
            obj.compute_y_fn = compute_y_fn;
            obj.y_target = y_target;
            obj.tol = tol;
        end
        
        % no guarantees on behavior if update is called after update has
        % previously returned true
        function within_tolerance = update( obj )
            within_tolerance = obj.update_y();
            if ~within_tolerance
                obj.bisect_x();
            end
        end
        
    end
    
    
    methods % getters
        
        function value = get.x( obj )
            value = obj.x_values.values( end );
        end
        
        function value = get.y( obj )
            value = obj.y_values.values( end );
        end
        
        function value = get.x_previous( obj )
            value = obj.x_values.values( end - 1 );
        end
        
        function value = get.count( obj )
            value = obj.x_values.count;
        end
        
    end
    
    
    properties ( Access = private )
        lower(1,1) double {mustBeReal,mustBeFinite}
        upper(1,1) double {mustBeReal}
        compute_y_fn function_handle
        y_target(1,1) double {mustBeReal,mustBeFinite}
        tol(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1e-5
    end
    
    
    methods ( Access = private )
        
        function within_tolerance = update_y( obj )
            xv = obj.x_values.values( end );
            yv = obj.compute_y_fn( xv );
            obj.y_values.append( yv );
            within_tolerance = obj.is_within_tolerance( yv );
        end
        
        function within = is_within_tolerance( obj, y )
            within = abs( y - obj.y_target ) <= obj.tol;
        end
        
        function xv = bisect_x( obj )
            if obj.is_below_target()
                xv = obj.increase();
            else
                xv = obj.decrease();
            end
            obj.x_values.append( xv );
        end
        
        function below = is_below_target( obj )
            below = obj.y < obj.y_target;
        end
        
        function xv = increase( obj )
            obj.lower = obj.x;
            if isinf( obj.upper )
                xv = obj.lower * 2;
            else
                xv = mean( [ obj.lower obj.upper ] );
            end
        end
        
        function xv = decrease( obj )
            obj.upper = obj.x;
            xv = mean( [ obj.lower obj.upper ] );
        end
        
    end
    
end

