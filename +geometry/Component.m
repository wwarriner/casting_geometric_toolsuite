classdef (Sealed) Component < handle
    
    properties ( GetAccess = public, SetAccess = private )
        
        path(1,1) string = ""
        name(1,1) string = ""
        
        faces uint64 {mustBePositive} = []
        vertices double {mustBeReal,mustBeFinite} = []
        normals double {mustBeReal,mustBeFinite} = []
        
        envelope(1,1) geometry.Envelope
        
        id(1,1) uint64 {mustBePositive} = 1
        cdata double {mustBeReal,mustBeFinite} = []
        
        
    end
    
    
    methods ( Access = public )
        
        function obj = Component( varargin )
            
            if nargin == 0 || 2 < nargin
                assert( false )
            end
            
            first = varargin{ 1 };
            if ischar( first ) || isstring( first )
                obj.construct_from_file( first );
            elseif isstruct( first )
                obj.construct_from_fv( varargin{ : } );
            else
                assert( false );
            end
            
        end
        
        
        function assign_id( obj, id )
            
            assert( 0 < id );
            obj.id = id;
            
        end
        
        
        function assign_color( obj, color )
            
            assert( isa( color, 'double' ) );
            assert( isvector( color ) );
            assert( numel( color ) == 3 );
            assert( all( 0.0 <= color ) && all( color <= 1.0 ) );
            obj.cdata = color;
            
        end
        
        
        function ph = plot( obj, axh )
            
            ph = patch( ...
                axh, ...
                'faces', obj.faces, ...
                'vertices', obj.vertices, ...
                'facecolor', obj.cdata ...
                );
            
        end
        
        
        function fv = get_fv( obj )
            
            fv.faces = obj.faces;
            fv.vertices = obj.vertices;
            fv.cdata = obj.cdata;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        DEFAULT_COLOR = [ 0.5 0.5 0.5 ];
        
    end
    
    
    methods ( Access = private )
        
        function construct_from_file( obj, file )
            
            assert( isfile( file ) );
            
            [ obj.path, obj.name ] = fileparts( file );
            
            [ coordinates, obj.normals ] = READ_stl( file );
            [ obj.faces, obj.vertices ] = CONVERT_meshformat( coordinates );
            
            obj.envelope = geometry.Envelope( obj );
            
            obj.cdata = obj.DEFAULT_COLOR;
            
        end
        
        
        function construct_from_fv( obj, varargin )
            
            assert( nargin == 3 );
            
            fv = varargin{ 1 };
            name_in = varargin{ 2 };
            
            assert( isstruct( fv ) || isobject( fv ) );
            if isstruct( fv )
                assert( isfield( fv, 'faces' ) );
                assert( isfield( fv, 'vertices' ) );
            elseif isobject( fv )
                assert( isprop( fv, 'faces' ) );
                assert( isprop( fv, 'vertices' ) );
            else
                assert( false )
            end
            
            assert( ischar( name_in ) || isstring( name_in ) );
            if ischar( name_in )
                assert( isvector( name_in ) );
            elseif isstring( name_in )
                assert( isscalar( name_in ) );
            else
                assert( false );
            end
            
            obj.path = '';
            obj.name = name_in;
            
            obj.faces = fv.faces;
            obj.vertices = fv.vertices;
            obj.normals = geometry.utils.compute_normals( obj );
            
            obj.envelope = geometry.Envelope( obj );
            
            obj.cdata = obj.DEFAULT_COLOR;
            
        end
        
    end
    
end

