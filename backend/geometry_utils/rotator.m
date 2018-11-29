classdef (Sealed) rotator < handle
    
    methods ( Access = public )
        
        function obj = rotator( angles, center_of_rotation )
            
            if nargin < 2
                center_of_rotation = [ 0 0 0 ];
            end
            obj.center_of_rotation = center_of_rotation;
            
            % angles length 2 applies for sand castings
            %  rotation about z produces the same process
            % angles length 3 applies for die casting
            %  injection direction is perpendicular to gravity
            if length( angles ) == 2
                angles( 3 ) = 0;
            end

            cx = cos( angles( 1 ) );
            cy = cos( angles( 2 ) );
            cz = cos( angles( 3 ) );

            sx = sin( angles( 1 ) );
            sy = sin( angles( 2 ) );
            sz = sin( angles( 3 ) );

            % X1Y2Z3 Euler Angles, extrinsic, active transformation
            obj.rotation_matrix = [ ...
                cy*cz, cz*sx*sy-cx*sz, cx*cz*sy+sx*sz; ...
                cy*sz, cx*cz+sx*sy*sz, cx*sy*sz-cz*sx; ...
                -sy, cy*sx, cx*cy ...
                ].';
            
        end
        
        
        function vec = rotate( obj, vec )
            
            vec = vec - obj.center_of_rotation;
            vec = vec * obj.rotation_matrix;
            vec = vec + obj.center_of_rotation;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        rotation_matrix
        center_of_rotation
        
    end
    
end

