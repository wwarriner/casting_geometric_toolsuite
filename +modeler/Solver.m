classdef (Abstract) Solver < handle
    
    methods ( Access = public )
        
        result = solve( obj, lhs, rhs, guess );
        count = get_iteration_count( obj );
        time = get_time( obj );
        
    end
    
end

