classdef ProcessKey < handle
    
    properties ( SetAccess = private )
        name(1,1) string
    end
    
    methods ( Access = public )
        function obj = ProcessKey( name )
            obj.name = name;
        end
        
        function instance = create_instance( obj, varargin )
            instance = feval( obj.name, varargin{ : } );
        end
    end
    
end

