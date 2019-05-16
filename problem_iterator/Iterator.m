classdef (Abstract) Iterator < handle
    
    methods ( Access = public, Abstract )
        
        iterate( obj, solver );
        
    end
    
end

