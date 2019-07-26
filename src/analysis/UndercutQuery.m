classdef Undercuts < handle
    % Undercuts identifies regions in any column lying between two points in the
    % interior, then finds the resulting connected components.
    
    properties ( GetAccess = public, SetAccess = private, Dependent )
        count(1,1) uint64
        label_array(:,:,:) uint64
    end
    
    methods ( Access = public )
        % - @interior is a logical array representing a rasterized solid body.
        function obj = Undercuts( interior )
            if nargin == 0
                return;
            end
            
            assert( islogical( interior ) );
            
            uc = obj.paint( interior );
            uc = remove_small_connected_regions( uc );
            cc = bwconncomp( uc );
            cc.NumObjects = uint64( cc.NumObjects );
            obj.cc = cc;
        end
    end
    
    methods % getters
        function value = get.count( obj )
            value = obj.cc.NumObjects;
        end
        
        function value = get.label_array( obj )
            value = labelmatrix( obj.cc );
        end
    end
    
    properties ( Access = private )
        cc(1,1) struct
    end
    
    methods ( Access = private, Static )
        function uc = paint( interior )
            [ rotated_interior, inverse ] = rotate_to_dimension( 3, interior );
            sz = size( rotated_interior );
            uc = zeros( sz );
            for k = 1 : sz( 3 )
                for j = 1 : sz( 2 )
                    painting = false;
                    [ uc, painting ] = obj.paint_forward( rotated_interior, uc, j, k, painting );
                    uc = obj.unpaint_reverse( rotated_interior, uc, j, k, painting );
                end
            end
            uc = rotate_from_dimension( uc, inverse );
        end
        
        function [ uc, painting ] = paint_forward( interior, uc, j, k, painting )
            for i = 1 : size( interior, 1 )
                if ~painting && interior( i, j, k )
                    painting = true;
                end
                if painting == true && ~interior( i, j, k )
                    uc( i, j, k ) = 1;
                end
            end
        end
        
        function uc = unpaint_reverse( interior, uc, j, k, painting )
            if ~painting
                return;
            end
            for i = size( interior, 1 ) : -1 : 1
                if painting == true
                    if ~interior( i, j, k )
                        uc( i, j, k ) = 0;
                    else
                        break;
                    end
                end
            end
        end
    end
    
end

