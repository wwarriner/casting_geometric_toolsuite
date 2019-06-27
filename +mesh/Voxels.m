classdef Voxels < handle
    
    properties ( Access = public )
        
        dimension_count
        
        element_count
        scale
        shape
        origin
        strides
        envelope
        
        interface_area
        element_volume
        
        voxels
        
    end
    
    
    methods ( Access = public )
        
        function obj = Voxels( element_count, envelope )
            
            obj.desired_element_count = element_count;
            obj.envelope = envelope;
            obj.scale = mesh.utils.compute_voxel_mesh_scale( ...
                obj.envelope, ...
                obj.desired_element_count ...
                );
            obj.desired_shape = mesh.utils.compute_voxel_mesh_desired_shape( ...
                obj.envelope, ...
                obj.scale ...
                );
            obj.origin = mesh.utils.compute_voxel_mesh_origin( ...
                obj.envelope, ...
                obj.desired_shape, ...
                obj.scale ...
                );
            obj.points = mesh.utils.compute_voxel_mesh_points( ...
                obj.desired_shape, ...
                obj.origin, ...
                obj.scale ...
                );
            obj.shape = cellfun( @numel, obj.points );
            obj.element_count = prod( obj.shape );
            if obj.dimension_count == 1
                obj.strides = 1;
            else
                obj.strides = [ 1 cumprod( obj.shape( 1 : end - 1 ) ) ];
            end
            obj.voxels = ones( obj.shape );
            
            obj.interface_area = obj.scale .^ 2;
            obj.element_volume = obj.scale .^ 3;
            
        end
        
        
        function paint_fv( obj, fv, value )
            
            to_be_painted = obj.rasterize( fv, value );
            obj.voxels = obj.paint( obj.voxels, to_be_painted );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        desired_element_count
        desired_shape
        points
        
    end
    
    
    methods ( Access = private )
        
        function voxels = rasterize( obj, fv, value )
            
            voxels = mesh.utils.rasterize_fv( fv, obj.points );
            voxels( voxels ~= 0 ) = value;
            
        end
        
        
        function voxels = paint( obj, voxels, new_voxels )
            
            assert( all( size( voxels ) == size( new_voxels ) ) );
            
            voxels( new_voxels > 0 ) = new_voxels( new_voxels > 0 );
            
        end
        
    end
    
end

