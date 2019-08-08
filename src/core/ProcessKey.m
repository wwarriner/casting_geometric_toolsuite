classdef ProcessKey < handle
    
    properties ( SetAccess = private )
        name(1,1) string
    end
    
    methods ( Access = public )
        function obj = ProcessKey( name )
            obj.name = name;
        end
        
        function instance = create_instance( obj, results, settings, varargin )
            settings = settings.processes.(obj.name());
            instance = feval( obj.name, results, settings, varargin{ : } );
        end
    end
    
end

