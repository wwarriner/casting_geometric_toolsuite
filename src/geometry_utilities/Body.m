classdef Body < handle
    
    properties
        id(1,1) uint64 {mustBePositive} = 1
        name(1,1) string = ""
    end
    
    properties ( SetAccess = private )
        faces(:,3) uint64 {mustBePositive}
        vertices(:,3) double {mustBeReal,mustBeFinite}
        normals(:,3) double {mustBeReal,mustBeFinite}
        facevertexcdata(1,:) double {mustBeReal,mustBeFinite} = Body.DEFAULT_COLOR
        surface_area(1,1) double {mustBeReal,mustBeFinite}
        volume(1,1) double {mustBeReal,mustBeFinite}
        centroid(1,3) double {mustBeReal,mustBeFinite}
        envelope Envelope
    end
    
    properties ( SetAccess = private, Dependent )
        fv(1,1) struct
        convex_hull_fv(1,1) struct
    end
    
    methods
        function obj = Body( fv )
            if nargin == 0
                return;
            end
            
            assert( isstruct( fv ) );
            assert( isfield( fv, 'faces' ) );
            assert( isfield( fv, 'vertices' ) );
            
            normals = compute_normals( fv );
            if isfield( fv, 'facevertexcdata' )
                facevertexcdata = fv.facevertexcdata;
            else
                facevertexcdata = obj.DEFAULT_COLOR;
            end
            
            triangle_areas = compute_triangle_areas( fv );
            surface_area = sum( triangle_areas );
            [ volume, centroid ] = compute_fv_volume( fv );
            envelope = Envelope( fv );
            
            obj.faces = fv.faces;
            obj.vertices = fv.vertices;
            obj.normals = normals;
            obj.facevertexcdata = facevertexcdata;
            obj.surface_area = surface_area;
            obj.volume = volume;
            obj.centroid = centroid;
            obj.envelope = envelope;
        end
        
        function value = get.fv( obj )
            value.faces = obj.faces;
            value.vertices = obj.vertices;
            value.facevertexcdata = obj.facevertexcdata;
        end
        
        function value = get.convex_hull_fv( obj )
            value = compute_convex_hull( obj.fv );
        end
        
        function set.facevertexcdata( obj, value )
            assert( isvector( value ) || ismatrix( value ) );
            if isvector( value )
                assert( ...
                    length( value ) == 3 ...
                    || length( value ) == size( obj.vertices, 1 ) ...
                    ); %#ok<MCSUP>
                if numel( value ) == 3
                    assert( all( 0.0 <= value ) && all( value <= 1.0 ) );
                end
            elseif ismatrix( value )
                assert( size( value, 1 ) == size( obj.vertices, 1 ) ); %#ok<MCSUP>
                assert( size( value, 2 ) == 3 );
            else
                assert( false )
            end
            
            obj.facevertexcdata = value;
        end
        
        function rotate( obj, rotation )
            assert( isscalar( rotation ) );
            assert( isa( rotation, 'Rotation' ) );
            
            obj.apply_transformation( rotation );
        end
        
        function scale( obj, scaling )
            assert( isscalar( scaling ) );
            assert( isa( scaling, 'Scaling' ) );
            
            obj.apply_transformation( scaling );
        end
        
        function translate( obj, translation )
            assert( isscalar( translation ) );
            assert( isa( translation, 'Translation' ) );
            
            obj.apply_transformation( translation );
        end
        
        function gobj = plot( obj, axh )
            gobj = patch( ...
                axh, ...
                'faces', obj.faces, ...
                'vertices', obj.vertices, ...
                'facecolor', obj.facevertexcdata ...
                );
        end
    end
    
    properties ( Access = private, Constant )
        DEFAULT_COLOR = [ 0.5 0.5 0.5 ];
    end
    
    methods ( Access = private )
        function apply_transformation( obj, transformation )
            new_fv = obj.fv;
            new_fv.vertices = transformation.apply( new_fv.vertices );
            n = compute_normals( new_fv );
            [ ~, c ] = compute_fv_volume( new_fv );
            e = Envelop( new_fv );
            
            obj.vertices = new_fv.vertices;
            obj.normals = n;
            obj.centroid = c;
            obj.envelope = e;
        end
    end
    
end

