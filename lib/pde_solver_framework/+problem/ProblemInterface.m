classdef (Abstract) ProblemInterface < handle
    
    methods ( Abstract )
        update_system( obj );
        apply_time_step( obj, dt );
    end
    
end

