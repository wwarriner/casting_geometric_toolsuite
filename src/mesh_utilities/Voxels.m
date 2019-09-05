classdef Voxels < handle & matlab.mixin.Copyable
    
    properties
        default_value(1,1) double
        values double
    end
    
    properties ( SetAccess = private )
        shape(1,:) uint32 {mustBeNonnegative}
        scale(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1.0
        origin(1,:) double {mustBeReal,mustBeFinite}
    end
    
    properties ( SetAccess = private, Dependent )
        dimension_count(1,1) uint32 {mustBeNonnegative}
        element_count(1,1) uint32 {mustBePositive}
        element_area(1,1) double {mustBeReal,mustBeFinite,mustBePositive}
        element_volume(1,1) double {mustBeReal,mustBeFinite,mustBePositive}
        external_elements(:,1) cell
        neighbor_pairs(:,2) uint32 {mustBePositive}
    end
    
    methods
        function obj = Voxels( element_count, envelope, default_value )
            if nargin < 3
                default_value = 0.0;
            end
            
            assert( isscalar( element_count ) )
            assert( isa( element_count, 'double' ) );
            assert( isreal( element_count ) );
            assert( isfinite( element_count ) );
            assert( 0.0 < element_count );
            
            assert( isscalar( envelope ) );
            assert( isa( envelope, 'Envelope' ) );
            
            assert( isscalar( default_value ) );
            assert( isa( default_value, 'double' ) );
            
            scale = obj.compute_scale( envelope, element_count );
            desired_shape = obj.compute_desired_shape( envelope, scale );
            origin = obj.compute_origin( envelope, desired_shape, scale );
            points = obj.compute_points( desired_shape, origin, scale );
            values = obj.create_array( points, default_value );
            
            obj.shape = size( values );
            obj.scale = scale;
            obj.origin = origin;
            obj.values = values;
            obj.points = points;
            obj.default_value = default_value;
        end
        
        function paint( obj, fv, value )
            to_paint = obj.rasterize( fv );
            obj.values( to_paint ) = double( value );
        end
        
        function add( obj, fv, value )
            to_paint = obj.rasterize( fv );
            obj.values( to_paint ) = obj.values( to_paint ) + double( value );
        end
        
        function clear( obj )
            obj.values( : ) = obj.default_value;
        end
        
        function clone = pad( obj, padsize )
            clone = obj.copy();
            new_origin = obj.origin - ( obj.scale .* double( padsize ) );
            new_values = padarray( obj.values, double( padsize ), obj.default_value );
            new_shape = size( new_values );
            new_points = obj.compute_points( new_shape, new_origin, obj.scale );
            clone.shape = new_shape;
            clone.origin = new_origin;
            clone.values = new_values;
            clone.points = new_points;
        end
        
        function set.values( obj, value )
            assert( all( size( value ) == obj.shape ) ); %#ok<MCSUP>
            obj.values = value;
        end
        
        function value = get.dimension_count( obj )
            value = ndims( obj.values );
        end
        
        function value = get.element_count( obj )
            value = numel( obj.values );
        end
        
        function value = get.strides( obj )
            value = 1;
            if obj.dimension_count > 1
                value = [ value cumprod( obj.shape( 1 : end - 1 ) ) ];
            end
        end
        
        function value = get.element_area( obj )
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
        
        function clone = copy_blank( obj )
            clone = obj.copy();
            clone.clear();
        end
    end
    
    properties ( Access = private )
        strides(1,:) uint32 {mustBeNonnegative}
        points(:,1) cell
    end
    
    methods ( Access = private )
        function array = rasterize( obj, fv )
            array = rasterize_fv( fv, obj.points );
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
        
        function array = create_array( points, value )
            array = value .* ones( cellfun( @numel, points ) );
        end
    end
    
end

