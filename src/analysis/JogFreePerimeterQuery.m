classdef JogFreePerimeterQuery < handle
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint64
        label_array(:,:,:) uint64
        binary_array(:,:,:) logical
    end
    
    methods
        function obj = JogFreePerimeterQuery( ...
                projected_perimeter_query, ...
                bounds, ...
                height ...
                )
            if nargin == 0
                return;
            end
            
            assert( isa( ...
                projected_perimeter_query, ...
                'ProjectedPerimeterQuery' ...
                ) );
            
            assert( ndims( bounds ) == 3 );
            assert( size( bounds, 3 ) == 2 );
            assert( isa( bounds, 'uint64' ) );
            
            assert( isscalar( height ) );
            assert( isa( height, 'uint64' ) );
            
            sz = [ size( projected_perimeter_query.label_array ) height ];
            jog_free = zeros( sz );
            for i = 1 : projected_perimeter_query.count
                proj_segment = projected_perimeter_query.label_array == i;
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
        function segment = unproject_segment( obj, bounds, segment, height )
            [ infimum, supremum ] = obj.compute_extremes( bounds, segment );
            bounds = cat( ...
                3, ...
                infimum * uint64( segment ), ...
                supremum * uint64( segment ) ...
                );
            segment = unproject( bounds, height );
        end
    end
    
    methods ( Access = private, Static )
        function [ infimum, supremum ] = ...
                compute_extremes( bounds, proj_segment )
            lower = bounds( :, :, 1 );
            infimum = max( lower( proj_segment ), [], 'all' );
            upper = bounds( :, :, 2 );
            supremum = min( upper( proj_segment ), [], 'all' );
        end
    end
    
end

