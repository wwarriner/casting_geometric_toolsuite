classdef KernelInterface < handle
    
    methods ( Access = public, Abstract )
        
        [ A, b, x0 ] = create_system( obj )
        
    end
    
end

