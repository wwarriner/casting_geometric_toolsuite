classdef Body < handle
    
    properties
        id(1,1) uint32 {mustBePositive} = 1
        name(1,1) string = ""
    end
    
    properties ( SetAccess = private )
        faces(:,3) uint32 {mustBePositive}
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
        
        function clone = rotate( obj, rotation )
            assert( isscalar( rotation ) );
            assert( isa( rotation, 'Rotation' ) );
            
            clone = obj.apply_transformation( rotation );
        end
        
        function clone = scale( obj, scaling )
            assert( isscalar( scaling ) );
            assert( isa( scaling, 'Scaling' ) );
            
            clone = obj.apply_transformation( scaling );
        end
        
        function clone = translate( obj, translation )
            assert( isscalar( translation ) );
            assert( isa( translation, 'Translation' ) );
            
            clone = obj.apply_transformation( translation );
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
        function clone = apply_transformation( obj, transformation )
            new_fv = obj.fv;
            new_fv.vertices = transformation.apply( new_fv.vertices );
            clone = Body( new_fv );
        end
    end
    
end

