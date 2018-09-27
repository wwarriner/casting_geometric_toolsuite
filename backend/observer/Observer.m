classdef Observer < handle
    
    methods ( Access = public, Abstract )
        
        printf( obj, varargin );
        
    end
    
end

