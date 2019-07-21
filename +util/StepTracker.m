classdef (Sealed) StepTracker < handle
    
    properties ( SetAccess = private )
        values(:,1) double = []
    end
    
    
    properties ( SetAccess = private, Dependent )
        running_totals
        total
        count
    end
    
    
    methods % getters
        
        function value = get.running_totals( obj )
            value = cumsum( obj.values );
        end
        
        function value = get.total( obj )
            value = sum( obj.values );
        end
        
        function value = get.count( obj )
            value = numel( obj.values );
        end
        
    end
    
    
    methods ( Access = public )
        
        function append( obj, value )
            obj.values( end + 1 ) = value;
        end
        
    end
    
end

