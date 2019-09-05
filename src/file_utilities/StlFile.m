classdef StlFile < handle
    
    properties ( SetAccess = private, Dependent )
        path(1,1) string
        name(1,1) string
        fv(1,1) struct
    end
    
    methods
        function obj = StlFile( file )
            assert( isfile( file ) );
            
            obj.file = file;
        end
        
        function value = get.path( obj )
            value = fileparts( obj.file );
        end
        
        function value = get.name( obj )
            [ ~, value ] = fileparts( obj.file );
        end
        
        function value = get.fv( obj )
            assert( isfile( obj.file ) );
            value = read_stl( obj.file );
        end
    end
    
    properties ( Access = private )
        file(1,1) string
    end
    
end

