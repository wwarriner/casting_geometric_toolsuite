classdef JogFreePerimeter < handle
    
    properties ( GetAccess = public, SetAccess = private, Dependent )
        count
        label_matrix
        perimeter
    end
    
    
    properties ( GetAccess = public, SetAccess = private )
        heights(:,1) double {mustBeReal,mustBeFinite,mustBeNonnegative} = []
    end
    
    
    methods ( Access = public )
        
        function obj = JogFreePerimeter( ...
                count, ...
                perimeter_label_matrix, ...
                projected_label_matrix, ...
                limits ...
                )
            if nargin == 0
                return;
            end
            
            assert( isscalar( count ) );
            assert( isa( count, 'uint64' ) );
            
            assert( ndims( perimeter_label_matrix ) == 3 );
            assert( isa( perimeter_label_matrix, 'double' ) );
            assert( numel( unique( perimeter_label_matrix ) ) - 1 == count );
            
            assert( ismatrix( projected_label_matrix ) );
            assert( isa( projected_label_matrix, 'double' ) );
            sz = size( perimeter_label_matrix );
            assert( all( sz( 1 : 2 ) == size( projected_label_matrix ) ) );
            assert( numel( unique( projected_label_matrix ) ) - 1 == count );
            
            assert( ndims( limits ) == 3 );
            assert( size( limits, 3 ) == 2 );
            assert( isa( limits, 'double' ) );
            sz = size( limits );
            assert( all( sz( 1 : 2 ) == size( projected_label_matrix ) ) );
            
            [ obj.values, obj.heights ] = obj.determine_jog_free( ...
                count, ...
                perimeter_label_matrix, ...
                projected_label_matrix, ...
                limits ...
                );
        end
        
    end
    
    
    methods % getters
        
        function value = get.count( obj )
            value = numel( unique( obj.values ) ) - 1;
        end
        
        function value = get.label_matrix( obj )
            value = obj.values;
        end
        
        function value = get.perimeter( obj )
            value = obj.values > 0;
        end
        
    end
    
    
    properties ( Access = private )
        values(:,:,:) double {mustBeReal,mustBeFinite,mustBeNonnegative} = []
    end
    
    
    methods ( Access = private, Static )
        
        function [ jog_free, heights ] = determine_jog_free( ...
                count, ...
                perimeter_label_matrix, ...
                projected_label_matrix, ...
                limits ...
                )
            import analyses.JogFreePerimeter;
            jog_free = zeros( size( perimeter_label_matrix ) );
            heights = zeros( count, 1 );
            for i = 1 : count
                projected_segment = projected_label_matrix == i;
                [ inf, sup ] = JogFreePerimeter.determine_extremes( limits, projected_segment );
                segment = perimeter_label_matrix == i;
                [ jog_free, gap ] = JogFreePerimeter.append_segment( jog_free, inf, sup, segment, i );
                heights( i ) = max( gap, 0 );
            end
        end
        
        function [ inf, sup ] = determine_extremes( limits, projected_segment )
            lower = limits( :, :, 1 );
            inf = max( lower( projected_segment ), [], 'all' );
            upper = limits( :, :, 2 );
            sup = min( upper( projected_segment ), [], 'all' );
        end
        
        function [ jog_free, gap ] = append_segment( jog_free, inf, sup, segment, index )
            import analyses.JogFreePerimeter;
            gap = sup - inf + 1;
            if 0 < gap
                current = JogFreePerimeter.determine_current_jog_free( segment, inf, sup );
                jog_free( current ) = index;
            end
        end
        
        function jog_free = determine_current_jog_free( segment, inf, sup )
            jog_free = false( size( segment ) );
            jog_free( segment ) = true;
            jog_free( :, :, 1 : inf - 1 ) = false;
            jog_free( :, :, sup + 1 : end ) = false;
        end
        
    end
    
end

