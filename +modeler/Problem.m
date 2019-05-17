classdef (Abstract) Problem < handle
    
    methods ( Access = public )
        
        prepare( obj );
        quality = solve( obj, time_step );
        finished = is_finished( obj );
        
    end
    
end

