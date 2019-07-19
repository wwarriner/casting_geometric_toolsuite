classdef (Sealed) StepTracker < handle
    
    properties ( SetAccess = private )
        values(:,1) double = []
        running_totals(:,1) double = []
    end
    
    
    properties ( SetAccess = private, Dependent )
        total
        count
    end
    
    
    methods % getters
        
        function value = get.total( obj )
            value = obj.running_totals( end );
        end
        
        function value = get.count( obj )
            value = numel( obj.values );
        end
        
    end
    
    
    methods ( Access = public )
        
        function append( obj, value )
            obj.values( end + 1 ) = value;
            if isempty( obj.running_totals )
                obj.running_totals( end + 1 ) = value;
            else
                obj.running_totals( end + 1 ) ...
                    = obj.running_totals( end ) + value;
            end
        end
        
    end
    
end

