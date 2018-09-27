classdef (Sealed) CommonWriter < handle
    
    properties ( GetAccess = public, SetAccess = private )
        
        name
        
    end
    
    
    properties ( Access = private )
        
        path
        spacing
        origin
        
    end
    
    
    methods ( Access = public )
        
        function obj = CommonWriter( output_path, name, Mesh )
            
            assert( ischar( name ) );
            
            obj.path = output_path;
            obj.name = name;
            obj.spacing = Mesh.spacing;
            obj.origin = Mesh.origin;
            
        end
        
        
        function prepare_output_path( obj )

            if ~exist( obj.path, 'dir' )
                mkdir( obj.path );
            end
            
        end
        
        
        function write_array( obj, title, a )
            
            if isempty( a ); return; end
            file_path = obj.compose_file_path( '%s_%s.vtk', title );
            vtkwrite( ...
                file_path, ...
                'structured_points', ...
                title, a, ...
                'spacing', obj.spacing( 1 ), obj.spacing( 2 ), obj.spacing( 3 ), ...
                'origin', obj.origin( 1 ), obj.origin( 2 ), obj.origin( 3 ) ...
                );
            
        end
        
        
        function write_colored_fv( obj, title, fvc )
            
            file_path = obj.compose_file_path( '%s_%s.vtk', title );
            vtkcoloredfacewriter( file_path, title, title, fvc );
            
        end
        
        
        function write_fv( obj, title, fv )
            
            write_fv_sequence( obj, title, fv );
            
        end
        
        
        function write_fv_sequence( obj, title, fvs )
            
            if isempty( fvs ); return; end
            if numel( fvs ) == 1
                if iscell( fvs )
                    fvs = fvs{ 1 };
                end
                file_path = obj.compose_file_path( '%s_%s.stl', title );
                stlwrite( file_path, fvs );
            else
                for i = 1 : numel( fvs )
                    
                    file_path = obj.compose_file_path( '%s_%s_%i.stl', title, i );
                    stlwrite( file_path, fvs{ i } );
                    
                end
            end
            
        end
        
        
        function write_table( obj, title, table )
            
            if isempty( table ); return; end
            file_path = obj.compose_file_path( '%s_%s.csv', title );
            writetable( table, file_path );
            
        end
        
        
        function success = copy_file( obj, path )
            
            success = false;
            if isfile( path )
                copyfile( path, obj.compose_file_path( '%s.stl' ) );
                success = true;
            end
            
        end
        
    end
    
    
    methods ( Access = private )
        
        % user must include %s at start of formatspec for base name
        function file_path = compose_file_path( obj, formatspec, varargin )
            
            file_name = sprintf( formatspec, obj.name, varargin{ : } );
            file_path = fullfile( obj.path, char( file_name ) );
            
        end
        
    end
    
end

