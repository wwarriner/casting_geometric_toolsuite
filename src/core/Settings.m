classdef Settings < DynamicPropertyTree
    
    methods
        function obj = Settings( file )
            if nargin == 0
                return;
            end
            
            if ischar( file )
                file = string( file );
            end
            assert( isstring( file ) );
            assert( isscalar( file ) );
            
            obj.read_from_file( file );
        end
        
        function read_from_file( obj, file )
            assert( isfile( file ) );
            
            s = read_json_file( file );
            obj.build( s, string( mfilename( 'class' ) ) );
        end
        
        function apply( obj, other_obj, silent )
            if nargin < 3
                silent = false;
            end
            fields = string( fieldnames( other_obj ) );
            count = numel( fields );
            for i = 1 : count
                key = fields( i );
                mp = findprop( other_obj, key );
                if ~strcmpi( mp.SetAccess, 'public' )
                    continue;
                end
                if ~isprop( obj, key )
                    if ~silent
                        fprintf( 2, obj.missing_msg( key ) );
                    end
                    continue;
                end
                other_obj.(key) = obj.(key);
            end
        end
        
        function write( obj, file )
            assert( isstring( file ) );
            
            s = obj.struct();
            write_json_file( file, s );
        end
        
        function value = properties( obj )
            value = properties@DynamicPropertyTree( obj );
        end
    end
    
end

