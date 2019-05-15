classdef (Sealed) Options < Property
    
    methods ( Access = public )
        
        function obj = Options( varargin )
            
            OPTION_DEFAULTS_PATH = which( 'option_defaults.json' );
            if ~isfile( OPTION_DEFAULTS_PATH )
                assert( false );
            end
            obj.create( OPTION_DEFAULTS_PATH );
            
            if nargin >= 2
                obj.update( varargin{ 1 } );
            end
            
        end
        
        
        function keys = list( obj )
            
            keys = obj.list_props( obj, {}, {} );
            
        end
        
    end
    
    
    methods ( Access = private )
        
        function keys = list_props( obj, value, ancestry, keys )
            
            fields = fieldnames( value );
            for i = 1 : numel( fields )

                field = fields{ i };
                current_keys = [ ancestry field ];
                if isa( value.(field), 'Property' )
                    keys = obj.list_props( ...
                        value.(field), ...
                        current_keys, ...
                        keys ...
                        );
                else
                    key = strjoin( current_keys, '.' );
                    keys{ end + 1, 1 } = key;
                end

            end
            
        end
        
        
        function create( obj, path )
            
            values = jsondecode( fileread( path ) );
            obj.add_props( values );
            
        end
        
        
        function add_props( obj, value, keys )
            
            if nargin < 3
                keys = {};
            end
            
            if ~isa( value, 'struct' )
                obj.add( strjoin( keys, '.' ), value );
            else
                fields = fieldnames( value );
                for i = 1 : numel( fields )
                    
                    field = fields{ i };
                    obj.add_props( ...
                        value.(field), ...
                        [ keys { field } ] ...
                        );
                    
                end
            end
            
        end
        
        
        function update( obj, path )
            
            values = jsondecode( fileread( path ) );
            obj.set_props( values );
            
        end
        
        
        function set_props( obj, value, keys )
            
            if nargin < 3
                keys = {};
            end
            
            if ~isa( value, 'struct' )
                obj.set( strjoin( keys, '.' ), value );
            else
                fields = fieldnames( value );
                for i = 1 : numel( fields )
                    
                    field = fields{ i };
                    obj.set_props( ...
                        value.(field), ...
                        [ keys { field } ] ...
                        );
                    
                end
            end
            
        end
        
    end
    
end

