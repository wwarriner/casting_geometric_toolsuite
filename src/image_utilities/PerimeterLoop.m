classdef PerimeterLoop < handle
    
    properties
        perimeter(:,:) logical
        distances(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        indices(:,1) uint32 {mustBePositive}
    end
    
    methods
        function obj = PerimeterLoop( image )
            cc = bwconncomp( image );
            assert( cc.NumObjects == 1 );
            
            im = image;
            [ x, y ] = ind2sub( size( im ), find( im, 1 ) ) ;
            trace = bwtraceboundary( im, [ x y ], obj.START_DIRECTION );
            indices = sub2ind( size( im ), trace( :, 1 ), trace( :, 2 ) );
            
            trace_diff = diff( trace, 1 );
            distances = sqrt( sum( abs( trace_diff ), 2 ) );
            
            obj.indices = indices( 1 : end - 1);
            obj.distances = distances;
        end
    end
    
    properties ( Access = private )
        neighbor_distances(:,1) = [ 1 sqrt( 2 ) ];
    end
    
    properties ( Access = private )
        START_DIRECTION = "W";
    end
    
end

