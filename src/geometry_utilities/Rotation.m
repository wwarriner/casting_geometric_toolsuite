classdef Rotation < handle & matlab.mixin.Copyable
    
    properties
        angles(1,3) double {mustBeReal,mustBeFinite} = [ 0 0 0 ]
        origin(1,3) double {mustBeReal,mustBeFinite} = [ 0 0 0 ]
    end
    
    methods
        function v = apply( obj, v )
            assert( isvector( v ) || ismatrix( v ) );
            assert( size( v, 2 ) == 3 );
            
            r = obj.generate_rotation_matrix( obj.angles );
            v = v - obj.origin;
            v = v * r;
            v = v + obj.origin;
        end
    end
    
    methods ( Access = private, Static )
        function r = generate_rotation_matrix( angles )
            cx = cos( angles( 1 ) );
            cy = cos( angles( 2 ) );
            cz = cos( angles( 3 ) );
            
            sx = sin( angles( 1 ) );
            sy = sin( angles( 2 ) );
            sz = sin( angles( 3 ) );
            
            r = [ ...
                cy*cz, cz*sx*sy-cx*sz, cx*cz*sy+sx*sz; ...
                cy*sz, cx*cz+sx*sy*sz, cx*sy*sz-cz*sx; ...
                -sy, cy*sx, cx*cy ...
                ].';
        end
    end
    
end

