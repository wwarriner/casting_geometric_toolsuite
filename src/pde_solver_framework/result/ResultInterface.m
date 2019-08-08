classdef ResultInterface < handle
    
    properties ( Abstract, SetAccess = private )
        values
    end
    
    methods ( Abstract )
        update( obj )
    end
    
end

