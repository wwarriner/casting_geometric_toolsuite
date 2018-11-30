classdef (Sealed) Options < dynamicprops
    
    methods ( Access = public )
        
        function obj = Options( option_defaults_path, varargin )
            
            if ~isempty( option_defaults_path )
                Options.update_values( option_defaults_path, @obj.assign_properties );
            end
            
            if nargin == 2
                Options.update_values( varargin{ 1 }, @obj.assign_properties );
            elseif nargin == 4
                Options.update_values( varargin{ 1 }, @obj.assign_properties );
                obj.assign_user( 'input_stl_path', varargin{ 2 } );
                obj.assign_user( 'output_path', varargin{ 3 } );
            else
                error( 'Incorrect arguments' );
            end
            
        end
        
    end
    
    
    methods ( Access = private )
        
        function assign_properties( obj, key, value )
            
            obj.add_property( key );
            obj.(key) = value;
            
        end
        
        
        function add_property( obj, key )
            
            P = addprop( obj, key );
            P.Access = 'public';
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function update_values( path, update_func )
            
            values = jsondecode( fileread( path ) );
            fn = fieldnames( values );
            for i = 1 : numel( fn )
                
                key = fn{ i };
                value = values.(key);
                update_func( key, value );
                
            end
            
        end
        
    end
    
end

