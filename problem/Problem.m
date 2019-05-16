classdef (Abstract) Problem < handle
    
    methods ( Access = public )
        
        quality = solve( obj, time_step );
        
    end
    
end

