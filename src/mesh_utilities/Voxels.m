classdef Voxels < handle & matlab.mixin.Copyable
    
    properties
        default_value(1,1) double
        values double
    end
    
    properties ( SetAccess = private )
        shape(1,:) uint32 {mustBeNonnegative}
        scale(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1.0
        origin(1,:) double {mustBeReal,mustBeFinite}
        normals(:,1) cell
    end
    
    properties ( SetAccess = private, Dependent )
        dimension_count(1,1) uint32 {mustBeNonnegative}
        element_count(1,1) uint32 {mustBePositive}
        strides(1,:) uint32 {mustBeNonnegative}
        element_area(1,1) double {mustBeReal,mustBeFinite,mustBePositive}
        element_volume(1,1) double {mustBeReal,mustBeFinite,mustBePositive}
        external_elements(:,1) cell
        neighbor_pairs(:,2) uint32 {mustBePositive}
        body_count(1,1) uint32 {mustBeNonnegative}
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
            grid = obj.compute_grid( desired_shape, origin, scale );
            values = obj.create_array( grid, default_value );
            
            obj.shape = size( values );
            obj.scale = scale;
            obj.origin = origin;
            obj.values = values;
            obj.grid = grid;
            obj.default_value = default_value;
        end
        
        function paint( obj, fv, value )
            r = Raster( obj.grid, fv );
            obj.normals{ end + 1 } = r.normals;
            obj.values( r.interior ) = double( value );
        end
        
        function add( obj, fv, value )
            to_paint = obj.rasterize( fv );
            obj.values( to_paint ) = obj.values( to_paint ) + double( value );
        end
        
        function clear( obj )
            obj.values( : ) = obj.default_value;
            obj.normals = {};
        end
        
        % @subset_line creates an axially-aligned linear subset of the
        % current voxels. This method ONLY supports 3D and 2D Voxel objects
        % (@dimension_count == 3 or 2).
        function clone = subset_line( obj, slice_indices, line_dimension )
            assert( ismember( obj.dimension_count, [ 2 3 ] ) );
            
            assert( isnumeric( slice_indices ) );
            assert( isreal( slice_indices ) );
            assert( all( isfinite( slice_indices ) ) );
            other_shape = obj.shape;
            other_shape( line_dimension ) = [];
            for i = 1 : numel( slice_indices )
                assert( 1 <= slice_indices( i ) );
                assert( slice_indices( i ) <= other_shape( i ) );
            end
            
            assert( isnumeric( line_dimension ) );
            assert( isreal( line_dimension ) );
            assert( isfinite( line_dimension ) );
            assert( ismember( line_dimension, 1 : obj.dimension_count ) );
            
            clone = obj.copy();
            
            new_shape = obj.shape( line_dimension );
            
            new_origin = obj.origin( line_dimension );
            
            subs = cellfun( ...
                @(x)1:obj.shape(x), ...
                num2cell( 1 : obj.dimension_count ), ...
                'uniformoutput', false ...
                );
            indices = num2cell( slice_indices );
            other_dims = 1 : obj.dimension_count;
            other_dims( line_dimension ) = [];
            [ subs{ other_dims } ] = deal( indices{ : } );
            new_values = squeeze( obj.values( subs{ : } ) );
            
            new_grid = obj.compute_grid( new_shape, new_origin, obj.scale );
            
            clone.shape = [ new_shape 1 ];
            clone.origin = new_origin;
            clone.values = new_values( : );
            clone.grid = new_grid;
        end
        
        % @subset_plane creates an axially-aligned planar subset of the
        % current voxels. This method ONLY supports 3D Voxel objects
        % (@dimension_count == 3).
        function clone = subset_plane( obj, slice_index, normal_dimension )
            assert( obj.dimension_count == 3 );
            
            assert( isnumeric( slice_index ) );
            assert( isreal( slice_index ) );
            assert( isfinite( slice_index ) );
            assert( 1 <= slice_index );
            assert( slice_index <= obj.shape( normal_dimension ) );
            
            assert( isnumeric( normal_dimension ) );
            assert( isreal( normal_dimension ) );
            assert( isfinite( normal_dimension ) );
            assert( ismember( normal_dimension, 1 : obj.dimension_count ) );
            
            clone = obj.copy();
            
            new_shape = obj.shape;
            new_shape( normal_dimension ) = [];
            new_shape = squeeze( new_shape );
            
            new_origin = obj.origin;
            new_origin( normal_dimension ) = [];
            new_origin = squeeze( new_origin );
            
            subs = cellfun( ...
                @(x)1:obj.shape(x), ...
                num2cell( 1 : obj.dimension_count ), ...
                'uniformoutput', false ...
                );
            subs{ normal_dimension } = slice_index;
            new_values = squeeze( obj.values( subs{ : } ) );
            
            new_grid = obj.compute_grid( new_shape, new_origin, obj.scale );
            
            clone.shape = new_shape;
            clone.origin = new_origin;
            clone.values = new_values;
            clone.grid = new_grid;
        end
        
        function clone = pad( obj, padsize )
            clone = obj.copy();
            new_origin = obj.origin - ( obj.scale .* double( padsize ) );
            new_values = padarray( obj.values, double( padsize ), obj.default_value );
            new_shape = size( new_values );
            new_grid = obj.compute_grid( new_shape, new_origin, obj.scale );
            clone.shape = new_shape;
            clone.origin = new_origin;
            clone.values = new_values;
            clone.grid = new_grid;
        end
        
        function value = get_surface_normal_map( obj, body_index )
            if nargin
                body_index = obj.body_count;
            end
            
            assert( 0 < obj.body_count );
            assert( 0 < body_index );
            assert( body_index <= obj.body_count );
            
            n = obj.normals{ body_index };
            nn = n{ :, { 'y' 'x' 'z' } };
            value = nan( [ obj.shape 3 ] );
            for normal_dimension = 1 : 3
                g = zeros( obj.shape );
                g( n.indices ) = nn( :, normal_dimension );
                value( :, :, :, normal_dimension ) = g;
            end
        end
        
        function set.values( obj, value )
            assert( all( size( value ) == obj.shape ) ); %#ok<MCSUP>
            obj.values = value;
        end
        
        function value = get.dimension_count( obj )
            if isvector( obj.values )
                value = 1;
            else
                value = ndims( obj.values );
            end
        end
        
        function value = get.element_count( obj )
            value = numel( obj.values );
        end
        
        function value = get.element_area( obj )
            value = obj.scale .^ ( double( obj.dimension_count ) - 1 );
        end
        
        function value = get.element_volume( obj )
            value = obj.scale .^ double( obj.dimension_count );
        end
        
        % - external is a cell array with @dimension_count elements, each
        % composed of element indices
        % - the first dimension_count vectors represent elements on the
        % negative axial faces
        % - the second dimension_count vectors represent elements on the
        % positive axial faces
        function value = get.external_elements( obj )
            if obj.dimension_count == 1
                value = { 1, obj.element_count };
                return;
            end
            augmented_strides = double( [ obj.strides( : ); obj.element_count ] );
            bases = cell( obj.dimension_count, 1 );
            for i = 1 : obj.dimension_count
                current_stride = augmented_strides( i );
                next_stride = augmented_strides( i + 1 );
                order = 1 : obj.dimension_count;
                order = [ order( order == i ) order( order ~= i ) ];
                bases{ i } = permute( 1 : current_stride : next_stride, order );
            end
            value = cell( 2 * obj.dimension_count, 1 );
            for i = 1 : obj.dimension_count
                order = 1 : obj.dimension_count;
                order = order( order ~= i );
                inds = 0;
                for j = 1 : numel( order )
                    inds = inds + bases{ order( j ) };
                end
                inds = inds( : ) - obj.dimension_count + 2;
                value{ i } = sort( uint32( inds ) );
                value{ i + obj.dimension_count } = sort( uint32( obj.element_count - inds + 1 ) );
            end
        end
        
        function value = get.neighbor_pairs( obj )
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
            value = sortrows( uint32( [ lhs rhs ] ), [ 2 1 ] );
        end
        
        function value = get.body_count( obj )
            value = numel( obj.normals );
        end
        
        function clone = copy_blank( obj )
            clone = obj.copy();
            clone.clear();
        end
    end
    
    properties ( Access = private )
        grid Grid
    end
        
    methods
        function value = get.strides( obj )
            value = 1;
            if obj.dimension_count > 1
                value = [ value cumprod( obj.shape( 1 : end - 1 ) ) ];
            end
        end
    end
    
    methods ( Access = private, Static )
        function scale = compute_scale( envelope, count )
            scale = ( envelope.volume / double( count ) ) ...
                .^ ( 1.0 / double( envelope.dimension_count ) );
        end
        
        function shape = compute_desired_shape( envelope, scale )
            shape = round( envelope.lengths ./ scale );
        end
        
        function origin = compute_origin( envelope, shape, scale )
            mesh_lengths = double( shape ) .* scale;
            origin_offsets = ( mesh_lengths - envelope.lengths ) ./ 2;
            origin = envelope.min_point - origin_offsets;
        end
        
        function grid = compute_grid( shape, origin, scale )
            points = arrayfun( ...
                @(x,y)Voxels.generate_points(x,y,scale), ...
                origin, ...
                double( shape ), ...
                'uniformoutput', false ...
                );
            grid = Grid( points );
        end
        
        function points = generate_points( origin, shape, scale )
            if shape == 0
                points = origin;
            else
                points = origin + scale .* ( 1 : shape ) - scale / 2;
            end
        end
        
        function array = create_array( grid, value )
            assert( 1 <= numel( grid.points ) );
            if numel( grid.points ) <= 1 
                array = value .* ones( numel( grid.points{ 1 } ), 1 );
            else
                array = value .* ones( cellfun( @numel, grid.points ) );
            end
        end
    end
    
end

