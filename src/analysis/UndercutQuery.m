classdef UndercutQuery < handle
    % @Undercuts identifies regions in any column lying between two points in
    % the interior, then finds the resulting connected components.
    
    properties ( SetAccess = private, Dependent )
        count(1,1) double
        label_array(:,:,:) uint32
    end
    
    methods
        % Inputs:
        % - @interior is a logical array representing a rasterized solid body.
        function obj = UndercutQuery( interior )
            if nargin == 0
                return;
            end
            
            assert( islogical( interior ) );
            
            uc = obj.paint( interior );
            uc = remove_small_connected_regions( uc );
            cc = bwconncomp( uc );
            cc.NumObjects = uint32( cc.NumObjects );
            obj.cc = cc;
        end
        
        function value = get.count( obj )
            value = obj.cc.NumObjects;
        end
        
        function value = get.label_array( obj )
            value = uint32( labelmatrix( obj.cc ) );
        end
    end
    
    properties ( Access = private )
        cc(1,1) struct
    end
    
    methods ( Access = private, Static )
        function uc = paint( interior )
            [ rotated, inverse ] = rotate_to_dimension( 3, interior );
            sz = size( rotated );
            uc = zeros( sz );
            for k = 1 : sz( 3 )
                for j = 1 : sz( 2 )
                    painting = false;
                    [ uc, painting ] = UndercutQuery.paint_forward( ...
                        rotated, ...
                        uc, ...
                        j, ...
                        k, ...
                        painting ...
                        );
                    uc = UndercutQuery.unpaint_reverse( ...
                        rotated, ...
                        uc, ...
                        j, ...
                        k, ...
                        painting ...
                        );
                end
            end
            uc = rotate_from_dimension( uc, inverse );
        end
        
        function [ uc, painting ] = paint_forward( image, uc, j, k, painting )
            for i = 1 : size( image, 1 )
                if ~painting && image( i, j, k )
                    painting = true;
                end
                if painting == true && ~image( i, j, k )
                    uc( i, j, k ) = 1;
                end
            end
        end
        
        function uc = unpaint_reverse( image, uc, j, k, painting )
            if ~painting
                return;
            end
            for i = size( image, 1 ) : -1 : 1
                if painting == true
                    if ~image( i, j, k )
                        uc( i, j, k ) = 0;
                    else
                        break;
                    end
                end
            end
        end
    end
    
end

