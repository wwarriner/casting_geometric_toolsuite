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

            cx = cos( angles( 1 ) );
            cy = cos( angles( 2 ) );
            cz = cos( angles( 3 ) );

            sx = sin( angles( 1 ) );
            sy = sin( angles( 2 ) );
            sz = sin( angles( 3 ) );

            % X1Y2Z3 Euler Angles, extrinsic, active transformation
            obj.r = [ ...
                cy*cz, cz*sx*sy-cx*sz, cx*cz*sy+sx*sz; ...
                cy*sz, cx*cz+sx*sy*sz, cx*sy*sz-cz*sx; ...
                -sy, cy*sx, cx*cy ...
                ].';
            
        end
        
        
        function vec = rotate( obj, vec )
                
            vec = vec * obj.r;
            
        end
        
    end
end

