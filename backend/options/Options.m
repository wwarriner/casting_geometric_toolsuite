classdef (Sealed) Options < Property
    
    methods ( Access = public )
        
        function obj = Options( option_defaults_path, varargin )
            
            if ~isempty( option_defaults_path )
                obj.create( option_defaults_path );
            end
            
            if nargin >= 2
                obj.update( varargin{ 1 } );
            end
            
            if nargin >= 3
                obj.stl_path.set( varargin{ 2 } );
            end
            
            if nargin >= 4
                obj.output_path.set( varargin{ 3 } );
            end
            
        end
        
    end
    
    
    methods ( Access = private )
        
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

