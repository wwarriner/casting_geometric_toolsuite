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
        
        array
        
    end
    
    
    methods ( Access = public )
        
        function obj = Voxels( element_count, envelope )
            
            obj.desired_element_count = element_count;
            obj.envelope = envelope;
            obj.dimension_count = envelope.dimension_count;
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
            obj.array = zeros( obj.shape );
            
            obj.interface_area = obj.scale .^ 2;
            obj.element_volume = obj.scale .^ 3;
            
        end
        
        
        function paint( obj, fv, value )
            
            to_paint = obj.rasterize( fv, value );
            obj.array( to_paint > 0 ) = to_paint( to_paint > 0 );
            
        end
        
        
        % - external is a cell array with 2 * dimension_count vectors, each
        % composed of element indices
        % - the first dimension_count vectors represent elements on the
        % negative faces
        % - the second dimension_count vectors represent elements on the
        % positive faces
        function elements = get_external_elements( obj )
            
            if obj.dimension_count == 1
                elements = { 1, 1 };
                return;
            end
            
            augmented_strides = [ obj.strides( : ); obj.element_count ];
            
            bases = cell( obj.dimension_count, 1 );
            for i = 1 : obj.dimension_count
                
                current_stride = augmented_strides( i );
                next_stride = augmented_strides( i + 1 );
                order = 1 : obj.dimension_count;
                order = [ order( order == i ) order( order ~= i ) ];
                bases{ i } = permute( 1 : current_stride : next_stride, order );
                
            end
            
            elements = cell( 2 * obj.dimension_count, 1 );
            for i = 1 : obj.dimension_count
                
                order = 1 : obj.dimension_count;
                order = order( order ~= i );
                inds = 0;
                for j = 1 : numel( order )
                    
                    inds = inds + bases{ order( j ) };
                    
                end
                inds = inds( : ) - obj.dimension_count + 2;
                elements{ i } = inds;
                elements{ i + obj.dimension_count } = obj.element_count - inds;
                
            end
            
        end
        
        
        function pairs = get_neighbor_pairs( obj )
            
            base = true( obj.element_count, obj.dimension_count );
            ext = obj.get_external_elements();
            for i = 1 : obj.dimension_count
                base( ext{ i }, i ) = false;
            end
            connectivity = spdiags2( ...
                base, ...
                obj.strides, ...
                obj.element_count, ...
                obj.element_count ...
                );
            [ lhs, rhs ] = find( connectivity );
            pairs = [ lhs rhs ];
            
        end
        
    end
    
    
    properties ( Access = private )
        
        desired_element_count
        desired_shape
        points
        
    end
    
    
    methods ( Access = private )
        
        function array = rasterize( obj, fv, value )
            
            array = mesh.utils.rasterize_fv( fv, obj.points );
            array( array ~= 0 ) = value;
            
        end
        
    end
    
end

