classdef PartingPerimeter < handle
    
    methods ( Access = public )
        
        function obj = PartingPerimeter( interior )
            if nargin == 0
                return;
            end
            
            assert( islogical( interior ) );
            
            % project
            p_interior = any( interior, 3 );
            % area
            
            % projected perimeter
            p_perimeter = bwperim( p_interior, conndef( 2, 'minimal' ) );
            
            % label matrix
            lm_p_perimeter = labelmatrix( bwconncomp( p_perimeter, conndef( 2, 'maximal' ) ) );
            
            % determine limits
            sz = size( interior );
            [ ~, ~, Z ] = meshgrid( 1 : sz( 2 ), 1 : sz( 1 ), 1 : sz( 3 ) );
            sweep = repmat( p_perimeter, [ 1 1 sz( 3 ) ] );
            Z( ~( sweep & interior ) ) = nan;
            limits = cat( 3, ...
                min( Z, [], 3 ), ...
                max( Z, [], 3 ) ...
                );
            
            % unprojection
            perimeter = zeros( size( interior ) );
            for i = 1 : sz( 1 )
                for j = 1 : sz( 2 )
                    if ~p_perimeter( i, j )
                        continue;
                    end
                    perimeter( i, j, limits( i, j, 1 ) : limits( i, j, 2 ) ) = lm_p_perimeter( i, j );
                end
            end
            
            % jog-free
            jf_perimeter = zeros( size( interior ) );
            cc_p_perimeter = bwconncomp( p_perimeter, conndef( 3, 'maximal' ) );
            lower_limit = limits( :, :, 1 );
            upper_limit = limits( :, :, 2 );
            for i = 1 : cc_p_perimeter.NumObjects
                indices = cc_p_perimeter.PixelIdxList{ i };
                highest_lower_limit = max( lower_limit( indices ), [], 'all' );
                lowest_upper_limit = min( upper_limit( indices ), [], 'all' );
                jf_gap = lowest_upper_limit - highest_lower_limit + 1;
                if 0 < jf_gap
                    current_perimeter = false( size( interior ) );
                    current_perimeter( perimeter == i ) = true;
                    current_perimeter( :, :, 1 : highest_lower_limit - 1 ) = false;
                    current_perimeter( :, :, lowest_upper_limit + 1 : end ) = false;
                    jf_perimeter( current_perimeter ) = i;
                end
            end
            
            % optimized parting line(s)
            
        end
        
    end
    
    
    properties ( Access = private )
        values double {mustBeReal,mustBeFinite,mustBeNonnegative} = []
    end
    
end

