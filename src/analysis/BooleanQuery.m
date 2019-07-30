classdef BooleanQuery < handle
    
    properties
        union_count
        union
        intersection_count
        intersection
        difference_count
        difference
        interface_count
        interface
    end
    
    methods
        function obj = BooleanQuery( lhs, rhs, element_count, envelope )
            % voxels of both
            % cc of both
            % merge cc's
            
            % find interface indices
            % lhs - rhs
            % dilate result
            % intersect with rhs
        end
        
        function value = get.union_count( obj )
            v = obj.create_new_voxels();
            i = obj.
        end
    end
    
    properties ( Access = private )
        cc(1,1) struct
        interface_indices(:,1) uint32 {mustBePositive}
        element_count(1,1) uint32 {mustBePositive}
        envelope Envelope
    end
    
    methods ( Access = private )
        function v = create_new_voxels( obj )
            v = Voxels( obj.element_count, obj.envelope, false );
        end
        
        function inds = get_union_indices( obj )
            inds = builtin( ...
                'union', ...
                obj.cc.PixelIdxList{ 1 }, ...
                obj.cc.PixelIdxList{ 2 } ...
                );
        end
        
        function inds = get_intersection_indices( obj )
            inds = builtin( ...
                'intersection', ...
                obj.cc.PixelIdxList{ 1 }, ...
                obj.cc.PixelIdxList{ 2 } ...
                );
        end
        
        function inds = get_difference_indices( obj )
            inds = setdiff( ...
                obj.cc.PixelIdxList{ 1 }, ...
                obj.cc.PixelIdxList{ 2 } ...
                );
        end
        
        function inds = get_interface_indices( obj )
            % rhs - lhs
        end
    end
    
end

