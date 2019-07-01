classdef Voxels < handle
    
    properties ( Access = public )
        
        dimension_count(1,1) uint64 {mustBePositive} = 1
        element_count(1,1) uint64 {mustBePositive} = 1
        scale(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1
        shape(1,:) uint64 {mustBeReal,mustBeFinite,mustBePositive} = 1
        origin(1,:) double {mustBeReal,mustBeFinite} = 1
        strides(1,:) uint64 {mustBeReal,mustBeFinite,mustBePositive} = 1
        envelope(1,1) geometry.Envelope
        
        interface_area(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1
        element_volume(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1
        
        array uint64 = []
        
    end
    
    
    methods ( Access = public )
        
        function obj = Voxels( element_count, envelope )
            
            obj.desired_element_count = element_count;
            obj.envelope = envelope;
            obj.dimension_count = envelope.dimension_count;
            obj.scale = obj.compute_scale( ...
                obj.envelope, ...
                obj.desired_element_count ...
                );
            obj.desired_shape = obj.compute_desired_shape( ...
                obj.envelope, ...
                obj.scale ...
                );
            obj.origin = obj.compute_origin( ...
                obj.envelope, ...
                obj.desired_shape, ...
                obj.scale ...
                );
            obj.points = obj.compute_points( ...
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
                double( obj.strides ), ...
                double( obj.element_count ), ...
                double( obj.element_count ) ...
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
            
            array = mesh.voxel.rasterize_fv( fv, obj.points );
            array( array ~= 0 ) = value;
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function scale = compute_scale( envelope, count )
            
            scale = ( envelope.volume / count ) .^ ( 1.0 / 3.0 );
            
        end
        
        
        function shape = compute_desired_shape( envelope, scale )
            
            shape = floor( envelope.lengths ./ scale );
            
        end
        
        
        function origin = compute_origin( envelope, shape, scale )
            
            mesh_lengths = shape .* scale;
            origin_offsets = ( mesh_lengths - envelope.lengths ) ./ 2;
            origin = envelope.min_point - origin_offsets;
            
        end
        
        
        function points = compute_points( shape, origin, scale )
            
            points = arrayfun( ...
                @(x,y) x + linspace( 0, scale, y ) .* y, ...
                origin, ...
                shape, ...
                'uniformoutput', false ...
                );
            
        end
        
    end
    
end

