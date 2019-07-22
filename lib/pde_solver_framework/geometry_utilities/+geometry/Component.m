classdef Component < handle
    
    properties
        id(1,1) uint64 {mustBePositive} = 1
    end
    
    properties ( SetAccess = private )
        path(1,1) string = ""
        name(1,1) string = ""
        faces(:,3) uint64 {mustBePositive} = []
        vertices(:,3) double {mustBeReal,mustBeFinite} = []
        normals(:,3) double {mustBeReal,mustBeFinite} = []
        cdata(1,3) double {mustBeReal,mustBeFinite} = geometry.Component.DEFAULT_COLOR
        envelope(1,1) geometry.Envelope
    end
    
    properties ( Dependent )
        fv
    end
    
    methods
        function obj = Component( varargin )
            if nargin == 0
                return;
            end
            if 2 < nargin
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
        
        function value = get.fv( obj )
            value.faces = obj.faces;
            value.vertices = obj.vertices;
            value.normals = obj.normals;
            value.cdata = obj.cdata;
        end
        
        function set.cdata( obj, value )
            assert( isvector( value ) );
            assert( numel( value ) == 3 );
            assert( all( 0.0 <= value ) && all( value <= 1.0 ) );
            
            obj.cdata = value;
        end
        
        function gobj = plot( obj, axh )
            gobj = patch( ...
                axh, ...
                'faces', obj.faces, ...
                'vertices', obj.vertices, ...
                'facecolor', obj.cdata ...
                );
        end
    end
    
    methods ( Access = private )
        function construct_from_file( obj, file )
            assert( isfile( file ) );
            
            [ obj.path, obj.name ] = fileparts( file );
            [ coordinates, obj.normals ] = READ_stl( file );
            [ obj.faces, obj.vertices ] = CONVERT_meshformat( coordinates );
            obj.cdata = obj.DEFAULT_COLOR;
            obj.envelope = geometry.Envelope( obj );
        end
        
        function construct_from_fv( obj, varargin )
            assert( nargin == 3 );
            
            fv_in = varargin{ 1 };
            assert( isstruct( fv_in ) || isobject( fv_in ) );
            if isstruct( fv_in )
                assert( isfield( fv_in, 'faces' ) );
                assert( isfield( fv_in, 'vertices' ) );
            elseif isobject( fv_in )
                assert( isprop( fv_in, 'faces' ) );
                assert( isprop( fv_in, 'vertices' ) );
            else
                assert( false )
            end
            
            name_in = varargin{ 2 };
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
            obj.faces = fv_in.faces;
            obj.vertices = fv_in.vertices;
            obj.normals = geometry.utils.compute_normals( obj );
            obj.cdata = obj.DEFAULT_COLOR;
            obj.envelope = geometry.Envelope( obj );
        end
    end
    
    properties ( Access = private, Constant )
        DEFAULT_COLOR = [ 0.5 0.5 0.5 ];
    end
    
end

