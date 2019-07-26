classdef Voxels < handle
    
    properties ( GetAccess = public, SetAccess = private )
        scale(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1
        origin(1,:) double {mustBeReal,mustBeFinite} = 1
        envelope geometry.Envelope
        values double = []
    end
    
    
    properties ( SetAccess = private, Dependent )
        dimension_count
        element_count
        shape
        strides
        interface_area
        element_volume
        external_elements
        neighbor_pairs
    end
    
    
    methods ( Access = public )
        
        function obj = Voxels( element_count, envelope, default_value )
            if nargin < 3
                default_value = 0;
            end
            
            obj.desired_element_count = element_count;
            obj.envelope = envelope;
            obj.default_value = default_value;
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
            obj.values = obj.default_value .* ones( cellfun( @numel, obj.points ) );
        end
        
        function paint( obj, fv, value )
            to_paint = obj.rasterize( fv );
            obj.values( to_paint ) = value;
        end
        
    end
    
    
    methods % getters
        
        function value = get.dimension_count( obj )
            value = ndims( obj.values );
        end
        
        function value = get.element_count( obj )
            value = numel( obj.values );
        end
        
        function value = get.shape( obj )
            value = size( obj.values );
        end
        
        function value = get.strides( obj )
            value = 1;
            if obj.dimension_count > 1
                value = [ value cumprod( obj.shape( 1 : end - 1 ) ) ];
            end
        end
        
        function value = get.interface_area( obj )
            value = obj.scale .^ 2;
        end
        
        function value = get.element_volume( obj )
            value = obj.scale .^ 3;
        end
        
        % - external is a cell array with 2 * dimension_count vectors, each
        % composed of element indices
        % - the first dimension_count vectors represent elements on the
        % negative axial faces
        % - the second dimension_count vectors represent elements on the
        % positive axial faces
        function elements = get.external_elements( obj )
            if obj.dimension_count == 1
                elements = { 1, obj.shape() };
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
                elements{ i + obj.dimension_count } = obj.element_count - inds + 1;
            end
        end
        
        function pairs = get.neighbor_pairs( obj )
            base = true( obj.element_count, obj.dimension_count );
            ext = obj.external_elements;
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
        desired_element_count(1,1) uint64 {mustBeNonnegative} = 1
        desired_shape(1,:) uint64 {mustBeNonnegative} = 1
        points(1,:) cell = {}
        default_value(1,1) double = 0.0
    end
    
    
    methods ( Access = private )
        
        function array = rasterize( obj, fv )
            array = mesh.voxel.rasterize_fv( fv, obj.points );
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function scale = compute_scale( envelope, count )
            scale = ( envelope.volume / double( count ) ) .^ ( 1.0 / 3.0 );
        end
        
        function shape = compute_desired_shape( envelope, scale )
            shape = round( envelope.lengths ./ scale );
        end
        
        function origin = compute_origin( envelope, shape, scale )
            mesh_lengths = double( shape ) .* scale;
            origin_offsets = ( mesh_lengths - envelope.lengths ) ./ 2;
            origin = envelope.min_point - origin_offsets;
        end
        
        function points = compute_points( shape, origin, scale )
            points = arrayfun( ...
                @(x,y) x + scale .* ( 1 : y ) - scale / 2, ...
                origin, ...
                double( shape ), ...
                'uniformoutput', false ...
                );
        end
        
    end
    
end

