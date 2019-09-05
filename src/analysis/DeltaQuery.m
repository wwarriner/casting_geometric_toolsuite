classdef (Sealed) DeltaQuery < handle
    
    properties ( SetAccess = private, Dependent )
        delta(:,:,:) double {mustBeReal,mustBeFinite,mustBeNonnegative}
        count(1,1) uint32 {mustBePositive}
        shape(1,3) uint32 {mustBePositive}
        scale(1,1) double {mustBeReal,mustBeFinite,mustBePositive} % casting units
        spacing(1,3) double {mustBeReal,mustBeFinite,mustBePositive}
        origin(1,3) double {mustBeReal,mustBeFinite}
        envelope Envelope
        exterior(:,:,:) logical
        added(:,:,:) logical
        removed(:,:,:) logical
        unchanged(:,:,:) logical
        exterior_volume(1,1) double {mustBeReal,mustBeFinite}
        added_volume(1,1) double {mustBeReal,mustBeFinite}
        removed_volume(1,1) double {mustBeReal,mustBeFinite}
        unchanged_volume(1,1) double {mustBeReal,mustBeFinite}
        UNCHANGED_VALUE(1,1) double {mustBeReal,mustBeFinite}
    end
    
    properties ( Access = public, Constant )
        NAME = 'comparison'
        EXTERIOR_VALUE = 0;
        ADDED_VALUE = 1;
        REMOVED_VALUE = 2;
    end
    
    methods
        function obj = DeltaQuery( ...
                current_fv, ...
                revised_fv, ...
                desired_mesh_element_count ...
                )
            current = Body( current_fv );
            current.id = obj.REMOVED_VALUE;
            revised = Body( revised_fv );
            revised.id = obj.ADDED_VALUE;
            
            uvc = UniformVoxelCanvas( desired_mesh_element_count );
            uvc.default_body_id = obj.EXTERIOR_VALUE;
            uvc.mode = uvc.ACCUMULATE;
            uvc.add_body( current );
            uvc.add_body( revised );
            uvc.paint();
            
            obj.uvc = uvc;
        end
        
        function value = get.delta( obj )
            value = obj.uvc.voxels.values;
        end
        
        function value = get.count( obj )
            value = obj.uvc.voxels.element_count;
        end
        
        function value = get.shape( obj )
            value = obj.uvc.voxels.shape;
        end
        
        function value = get.scale( obj )
            value = obj.uvc.voxels.scale;
        end
        
        function value = get.spacing( obj )
            value = repmat( obj.scale, [ 1 3 ] );
        end
        
        function value = get.origin( obj )
            value = obj.uvc.voxels.origin;
        end
        
        function value = get.envelope( obj )
            value = obj.uvc.envelope;
        end
        
        function value = get.exterior( obj )
            value = ( obj.delta == obj.EXTERIOR_VALUE );
        end
        
        function value = get.added( obj )
            value = ( obj.delta == obj.ADDED_VALUE );
        end
        
        function value = get.removed( obj )
            value = ( obj.delta == obj.REMOVED_VALUE );
        end
        
        function value = get.unchanged( obj )
            value = ( obj.delta == obj.UNCHANGED_VALUE );
        end
        
        function value = get.exterior_volume( obj )
            value = sum( obj.exterior, 'all' );
        end
        
        function value = get.added_volume( obj )
            value = sum( obj.added, 'all' );
        end
        
        function value = get.removed_volume( obj )
            value = sum( obj.removed, 'all' );
        end
        
        function value = get.unchanged_volume( obj )
            value = sum( obj.unchanged, 'all' );
        end
        
        function value = get.UNCHANGED_VALUE( obj )
            value = obj.ADDED_VALUE + obj.REMOVED_VALUE;
        end
    end
    
    properties ( Access = private )
       uvc UniformVoxelCanvas
    end
    
end

