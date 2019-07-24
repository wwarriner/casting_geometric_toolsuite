classdef JogFreePerimeter < handle
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint64
        label_array(:,:,:) uint64
        binary_array(:,:,:) logical
    end
    
    methods
        function obj = JogFreePerimeter( projected_perimeter, bounds, height )
            if nargin == 0
                return;
            end
            
            assert( isa( projected_perimeter, 'ProjectedPerimeter' ) );
            
            assert( ndims( bounds ) == 3 );
            assert( size( bounds, 3 ) == 2 );
            assert( isa( bounds, 'uint64' ) );
            
            assert( isscalar( height ) );
            assert( isa( height, 'uint64' ) );
            
            jog_free = zeros( [ size( projected_perimeter.label_array ) height ] );
            for i = 1 : projected_perimeter.count
                proj_segment = projected_perimeter.label_array == i;
                segment = obj.unproject_segment( bounds, proj_segment, height );
                jog_free( segment ) = i;
            end
            obj.cc = label2cc( jog_free );
        end
        
        function value = get.count( obj )
            value = obj.cc.NumObjects;
        end
        
        function value = get.label_array( obj )
            value = labelmatrix( obj.cc );
        end
        
        function value = get.binary_array( obj )
            value = obj.label_array > 0;
        end
    end
    
    properties ( Access = private )
        cc(1,1) struct
    end
    
    methods ( Access = private )
        function segment = unproject_segment( obj, bounds, proj_segment, height )
            [ infimum, supremum ] = obj.compute_extremes( bounds, proj_segment );
            bounds = cat( ...
                3, ...
                infimum * uint64( proj_segment ), ...
                supremum * uint64( proj_segment ) ...
                );
            segment = unproject( bounds, height );
        end
    end
    
    methods ( Access = private, Static )
        function [ infimum, supremum ] = compute_extremes( bounds, proj_segment )
            lower = bounds( :, :, 1 );
            infimum = max( lower( proj_segment ), [], 'all' );
            upper = bounds( :, :, 2 );
            supremum = min( upper( proj_segment ), [], 'all' );
        end
    end
    
end

