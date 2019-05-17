classdef (Abstract) Problem < handle
    
    methods ( Access = public )
        
        prepare( obj );
        quality = solve( obj, time_step );
        finished = is_finished( obj );
        count = get_solver_count( obj );
        times = get_times( obj );
        
    end
    
end

