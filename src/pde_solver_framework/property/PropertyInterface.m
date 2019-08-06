classdef (Abstract) PropertyInterface < handle
    
    properties ( Abstract, Constant )
        name(1,1) string
    end
    
    methods ( Abstract )
        values = lookup( obj, varargin );
        value = reduce( obj, fn );
    end
    
end

