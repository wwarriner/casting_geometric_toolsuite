classdef SettingsFile < Settings
    
    methods
        function obj = SettingsFile( file )
            if nargin == 0
                return;
            end
            
            assert( isstring( file ) );
            
            obj.read_from_file( file );
        end
        
        function read_from_file( obj, file )
            read_from_file@Settings( obj, file );
            obj.file = file;
        end
        
        function varargout = subsref( obj, s )
            [ varargout{ 1 : nargout } ] = subsref@Settings( obj, s );
        end
        
        function obj = subsasgn( obj, s, varargin )
            obj = subsasgn@Settings( obj, s, varargin{ : } );
            obj.write( obj.file );
        end
        
        function value = properties( obj )
            value = properties@Settings( obj );
        end
    end
    
    properties ( Access = private )
        file(1,1) string
    end
    
end

