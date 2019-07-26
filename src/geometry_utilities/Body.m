classdef Body < handle
    
    properties
        id(1,1) uint64 {mustBePositive} = 1
        name(1,1) string = ""
    end
    
    properties ( SetAccess = private )
        faces(:,3) uint64 {mustBePositive}
        vertices(:,3) double {mustBeReal,mustBeFinite}
        normals(:,3) double {mustBeReal,mustBeFinite}
        cdata(1,3) double {mustBeReal,mustBeFinite} = geometry.Body.DEFAULT_COLOR
        envelope geometry.Envelope
    end
    
    properties ( Dependent )
        fv(1,1) struct
        convex_hull ConvexHull
    end
    
    methods
        function obj = Body( fv )
            if nargin == 0
                return;
            end
            
            assert( isstruct( fv ) );
            assert( isfield( fv, 'faces' ) );
            assert( isfield( fv, 'vertices' ) );
            
            obj.faces = fv.faces;
            obj.vertices = fv.vertices;
            obj.normals = geometry.utils.compute_normals( obj );
            if isfield( fv, 'cdata' )
                obj.cdata = fv.cdata;
            else
                obj.cdata = obj.DEFAULT_COLOR;
            end
            obj.envelope = geometry.Envelope( obj );
        end
        
        function value = get.fv( obj )
            value.faces = obj.faces;
            value.vertices = obj.vertices;
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
    
    properties ( Access = private, Constant )
        DEFAULT_COLOR = [ 0.5 0.5 0.5 ];
    end
    
end

