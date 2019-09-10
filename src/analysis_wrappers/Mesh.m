classdef Mesh < Process
    % @Mesh is a uniform voxel representation of the underlying @Casting, and 
    % contains information useful for downstream analyses. It provides methods
    % for unit conversions between mesh and casting units. It provides boolean 
    % operations for the interior. It provides methods for converting to a
    % mesh format suitable for use with a PDE solver.
    % Settings:
    % - @desired_element_count, REQUIRED FINITE, approximate number of uniform
    % voxels to use when meshing. Exact amount may differ slightly due to 
    % integer arithmetic.
    % Dependencies:
    % - @Casting
    
    properties
        desired_element_count(1,1) double {mustBeReal,mustBePositive} = inf
    end
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint32 {mustBePositive}
        shape(1,3) uint32 {mustBePositive} % mesh units
        scale(1,1) double {mustBeReal,mustBeFinite,mustBePositive} % casting units
        spacing(1,3) double {mustBeReal,mustBeFinite,mustBePositive}
        origin(1,3) double {mustBeReal,mustBeFinite}
        envelope Envelope % casting units
        interior(:,:,:) logical
        exterior(:,:,:) logical
        surface(:,:,:) logical
        normals(:,:,:,3) double
    end
    
    methods
        function obj = Mesh( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function legacy_run( obj, casting )
            obj.casting = casting;
            obj.run();
        end
        
        function value = get.count( obj )
            value = obj.voxels.element_count;
        end
        
        function value = get.shape( obj )
            value = obj.voxels.shape;
        end
        
        function value = get.scale( obj )
            value = obj.voxels.scale;
        end
        
        function value = get.spacing( obj )
            value = repmat( obj.scale, [ 1 3 ] );
        end
        
        function value = get.origin( obj )
            value = obj.voxels.origin;
        end
        
        function envelope = get.envelope( obj )
            envelope = obj.casting.envelope;
        end
        
        function value = get.interior( obj )
            value = logical( obj.voxels.values );
        end
        
        function value = get.exterior( obj )
            value = ~obj.interior;
        end
        
        function value = get.surface( obj )
            value = bwperim( obj.interior );
        end
        
        function value = get.normals( obj )
            value = obj.voxels.get_surface_normal_map();
        end
        
        function mesh_lengths = to_mesh_length( obj, casting_lengths )
            mesh_lengths = casting_lengths ./ obj.scale;
        end
        
        function mesh_areas = to_mesh_area( obj, casting_areas )
            mesh_areas = casting_areas ./ obj.voxels.element_area;
        end
        
        function mesh_volumes = to_mesh_volume( obj, casting_volumes )
            mesh_volumes = casting_volumes ./ obj.voxels.element_volume;
        end
        
        function casting_lengths = to_casting_length( obj, mesh_lengths )
            casting_lengths = mesh_lengths .* obj.scale;
        end
        
        function casting_areas = to_casting_area( obj, mesh_areas )
            casting_areas = mesh_areas .* obj.voxels.element_area;
        end
        
        function casting_volumes = to_casting_volume( obj, mesh_volumes )
            casting_volumes = mesh_volumes .* obj.voxels.element_volume;
        end
        
        function casting_position = to_casting_position( obj, mesh_position, scale_origin )
            s = Scaling;
            s.factor = obj.scale;
            s.origin = scale_origin;
            s_position = s.apply( mesh_position );
            t = Translation;
            t.shift = obj.origin;
            casting_position = t.apply( s_position );
        end
        
        function casting_body = move_to_casting( obj, mesh_body, scale_origin )
            s = Scaling;
            s.factor = obj.scale;
            s.origin = scale_origin;
            s_body = mesh_body.scale( s );
            t = Translation;
            t.shift = obj.origin;
            casting_body = s_body.translate( t );
        end
        
        function v = voxelize( obj, body )
            v = obj.voxels.copy_blank();
            v.paint( body.fv, true );
        end
        
        function im = unite( obj, im )
            assert( islogical( im ) );
            assert( all( size( im ) == obj.shape ) );
            
            im = im | obj.interior;
        end
        
        function im = intersect( obj, im )
            assert( islogical( im ) );
            assert( all( size( im ) == obj.shape ) );
            
            im = im & obj.interior;
        end
        
        function im = subtract( obj, im )
            assert( islogical( im ) );
            assert( all( size( im ) == obj.shape ) );
            
            im = im & ~obj.interior;
        end
        
        function im = interface( obj, im )
            assert( islogical( im ) );
            assert( all( size( im ) == obj.shape ) );
            
            inds = find_interface( obj.interior, im );
            im = false( obj.shape );
            im( inds ) = true;
        end
        
        % Same as calling @to_pde_mesh_by_ratio with input value 0.144.
        % This multiplies the total number of voxels by approximately 1.5.
        function value = to_pde_mesh( obj )
            value = obj.to_pde_mesh_by_ratio( 0.144 );
        end
        
        % @ratio is a double scalar or 1 by 3 double vector, unitless,
        % which is converted to a length with units of @Casting length
        % proportionally based on @Casting envelope.
        function [ value, pad_count ] = to_pde_mesh_by_ratio( obj, pad_ratio, varargin )
            pad_length = obj.casting.envelope.lengths .* pad_ratio;
            [ value, pad_count ] = obj.to_pde_mesh_by_length( pad_length, varargin{ : } );
        end
        
        % @length is a double scalar or 1 by 3 double vector with units of
        % @Casting length. Scalar values are replicated.
        function [ value, pad_count ] = to_pde_mesh_by_length( obj, pad_length, varargin )
            pad_count = uint32( round( obj.to_mesh_length( pad_length ) ) );
            value = obj.to_pde_mesh_by_count( pad_count, varargin{ : } );
        end
        
        % @pad_count is a double scalar or 1 by 3 uint32 vector, e.g. input
        % to padarray. Scalar values are replicated.
        function value = to_pde_mesh_by_count( obj, pad_count, melt_id, mold_id )
            assert( isa( pad_count, 'uint32' ) );
            assert( isscalar( pad_count ) || isvector( pad_count ) );
            if isscalar( pad_count )
                pad_count = repmat( pad_count, [ 1 3 ] );
            end
            if isvector( pad_count )
                assert( length( pad_count ) == 3 );
            end
            
            mesh_voxels = obj.voxels.copy();
            mesh_voxels.default_value = mold_id;
            mesh_voxels.values( obj.interior ) = melt_id;
            mesh_voxels.values( obj.exterior ) = mold_id;
            mesh_voxels = mesh_voxels.pad( pad_count );
            id_list = unique( mesh_voxels.values );
            material_ids = nan( max( id_list ), 1 );
            material_ids( id_list ) = id_list;
            value = UniformVoxelMesh( mesh_voxels, material_ids );
        end
        
        function value = to_array( obj )
            value = obj.interior;
        end
        
        function write( obj, output_files )
            output_files.write_array( obj.NAME, obj.to_array() );
            output_files.write_table( obj.NAME, obj.to_table() );
        end
        
        function s = saveobj( obj )
            s.desired_element_count = obj.desired_element_count;
            s.voxels = obj.voxels;
            s.values = obj.voxels.values;
        end
    end
    
    methods ( Access = public, Static )
        function name = NAME()
            name = string( mfilename( 'class' ) );
        end
        
        function obj = loadobj( s )
            obj = Mesh();
            obj.desired_element_count = s.desired_element_count;
            obj.voxels = s.voxels;
            obj.voxels.values = s.values;
        end
    end
    
    methods ( Access = protected )
        function update_dependencies( obj )
            casting_key = ProcessKey( Casting.NAME );
            obj.casting = obj.results.get( casting_key );
            
            assert( ~isempty( obj.casting ) );
        end
        
        function check_settings( obj )
            assert( isfinite( obj.desired_element_count ) );
        end
        
        function run_impl( obj )
            obj.prepare_voxels();
        end
        
        function value = to_table_impl( obj )
            value = list2table( ...
                { 'count' }, ...
                { obj.count } ...
                );
        end
    end
    
    properties ( Access = private )
        casting Casting
        voxels Voxels
    end
    
    methods ( Access = private )
        function prepare_voxels( obj )
            obj.printf( "Meshing...\n" );
            obj.voxels = Voxels( ...
                obj.desired_element_count, ...
                obj.casting.envelope, ...
                0 ...
                );
            obj.voxels.paint( obj.casting.fv, 1 );
            cc = bwconncomp( obj.voxels.values );
            r = regionprops3( cc, "volume" );
            [ ~, i ] = max( r.Volume );
            obj.voxels.values = zeros( obj.voxels.shape );
            obj.voxels.values( cc.PixelIdxList{ i } ) = 1;
        end
    end
    
end

