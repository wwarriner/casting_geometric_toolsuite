classdef OutputFiles < handle
    
    properties ( SetAccess = private )
        path
        name
    end
    
    methods ( Access = public )
        % Throws if output_folder exists, is not empty, and overwrite is false.
        % Destroys contents of output_folder if overwrite is true.
        function obj = OutputFiles( output_folder, name, overwrite )
            if nargin < 3
                overwrite = false;
            end
            assert( islogical( overwrite ) );
            
            assert( ~isfile( output_folder ) );
            assert( ~isempty( name ) );
            
            obj.prepare_output_folder( output_folder, overwrite )
            
            obj.path = output_folder;
            obj.name = name;
        end
        
        function write_array( obj, title, a, spacing, origin )
            if nargin < 4
                spacing = [ 1 1 1 ];
            end
            if nargin < 5
                origin = [ 0 0 0 ];
            end
            
            assert( isscalar( title ) );
            assert( isstring( title ) );

            assert( ndims( a ) == 3 );
            
            assert( isvector( spacing ) );
            assert( length( spacing ) == 3 );
            assert( isa( spacing, 'double' ) );
            
            assert( isvector( origin ) );
            assert( length( spacing ) == 3 );
            assert( isa( spacing, 'double' ) );
            
            if isempty( a ); return; end
            file_path = obj.compose_file_path( '%s_%s.vtk', title );
            vtkwrite( ...
                file_path, ...
                'structured_points', ...
                char( title ), a, ...
                'spacing', spacing( 1 ), spacing( 2 ), spacing( 3 ), ...
                'origin', origin( 1 ), origin( 2 ), origin( 3 ) ...
                );
        end
        
        function write_colored_fv( obj, title, fvc )
            assert( isscalar( title ) );
            assert( isstring( title ) );
            
            assert( isscalar( fvc ) );
            assert( isstruct( fvc ) );
            assert( isfield( fvc, 'faces' ) );
            assert( isfield( fvc, 'vertices' ) );
            assert( isfield( fvc, 'facevertexcdata' ) );
            
            file_path = obj.compose_file_path( '%s_%s.vtk', title );
            vtkcoloredfacewriter( file_path, title, title, fvc );
        end
        
        function write_fv( obj, title, fv )
            assert( isscalar( title ) );
            assert( isstring( title ) );
            
            assert( isscalar( fv ) );
            assert( isstruct( fv ) );
            assert( isfield( fv, 'faces' ) );
            assert( isfield( fv, 'vertices' ) );
            
            write_fv_sequence( obj, title, { fv } );
        end
        
        function write_fv_sequence( obj, title, fvs )
            assert( isscalar( title ) );
            assert( isstring( title ) );
            
            assert( iscell( fvs ) || isstruct( fvs ) );
            if isstruct( fvs )
                fvs = num2cell( fvs );
            end
            assert( iscell( fvs ) );
            
            if isempty( fvs ); return; end
            if numel( fvs ) == 1
                file_path = obj.compose_file_path( '%s_%s.stl', title );
                stlwrite( file_path, fvs{ 1 } );
            else
                for i = 1 : numel( fvs )
                    fv = fvs{ i };
                    file_path = obj.compose_file_path( '%s_%s_%i.stl', title, i );
                    stlwrite( file_path, fv );
                end
            end
        end
        
        function write_table( obj, title, table )
            assert( isscalar( title ) );
            assert( isstring( title ) );
            
            assert( istable( table ) );
            
            if isempty( table ); return; end
            file_path = obj.compose_file_path( '%s_%s.csv', title );
            writetable( table, file_path );
        end
    end
    
    methods ( Access = private )
        % user must include %s at start of formatspec for base name
        function file_path = compose_file_path( obj, formatspec, varargin )
            file_name = sprintf( formatspec, obj.name, varargin{ : } );
            file_path = fullfile( obj.path, char( file_name ) );
        end
    end
    
    methods ( Access = private, Static )
        function prepare_output_folder( output_folder, overwrite )
            exists = isfolder( output_folder );
            empty = is_folder_empty( output_folder );
            if exists && ~empty && ~overwrite
                ME = MException( ...
                    "OutputFiles:noOverwrite", ...
                    "Folder exists, is not empty, and overwrite off.\n" ...
                    + "%s", ...
                    output_folder ...
                    );
                throw( ME )
            else
                prepare_folder( output_folder );
            end
        end
    end
    
end

