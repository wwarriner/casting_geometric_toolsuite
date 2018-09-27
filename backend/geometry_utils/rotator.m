classdef rotator
    
    properties ( Access = private )
        
        r
        
    end
    
    methods
        
        function obj = rotator( angles )
            
            % angles length 2 applies for sand castings
            %  rotation about z produces the same process
            % angles length 3 applies for die casting
            %  injection direction is perpendicular to gravity
            if length( angles ) == 2
                angles( 3 ) = 0;
            end

            cx = cos( angles( 2 ) );
            cy = cos( angles( 1 ) );
            cz = cos( angles( 3 ) );

            sx = sin( angles( 2 ) );
            sy = sin( angles( 1 ) );
            sz = sin( angles( 3 ) );

            % X1Y2Z3 Tait-Bryan angles
            % from https://en.wikipedia.org/wiki/Euler_angles#Rotation_matrix
            obj.r = [ ...
                cy*cz,          -cy*sz,         sy; ...
                cx*sz+cz*sx*sy, cx*cz-sx*sy*sz, -cy*sx; ...
                sx*sz-cx*cz*sy, cz*sx+cx*sy*sz, cx*cy ...
                ].';
            
        end
        
        
        function vec = rotate( obj, vec )
                
            vec = vec * obj.r;
            
        end
        
    end
end

