classdef (Sealed) StepTracker < handle
    
    properties ( SetAccess = private )
        values(:,1) {mustBeNumeric,mustBeReal,mustBeFinite} = []
    end
    
    properties ( SetAccess = private, Dependent )
        running_totals(:,1) {mustBeNumeric,mustBeReal,mustBeFinite}
        total(1,1) {mustBeNumeric,mustBeReal,mustBeFinite}
        count(1,1) uint32
    end
    
    methods
        function value = get.running_totals( obj )
            value = cumsum( obj.values );
        end
        
        function value = get.total( obj )
            value = sum( obj.values );
        end
        
        function value = get.count( obj )
            value = uint32( numel( obj.values ) );
        end
    end
    
    methods ( Access = public )
        function append( obj, value )
            obj.values( end + 1 ) = value;
        end
    end
    
end

