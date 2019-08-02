classdef Mesh < Process
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint32 {mustBePositive}
        shape(1,3) uint32 {mustBePositive}
        scale(1,1) double {mustBeReal,mustBeFinite,mustBePositive} % casting units
        spacing(1,3) double {mustBeReal,mustBeFinite,mustBePositive}
        origin(1,3) double {mustBeReal,mustBeFinite}
        envelope Envelope
        interior(:,:,:) logical
        exterior(:,:,:) logical
        surface(:,:,:) logical
    end
    
    methods
        function obj = Mesh( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function run( obj )
            obj.obtain_inputs();
            obj.prepare_voxels();
        end
        
        function legacy_run( obj, casting, desired_element_count )
            obj.casting = casting;
            obj.desired_element_count = desired_element_count;
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
        
        function value = get.interior( obj )
            value = logical( obj.voxels.values );
        end
        
        function value = get.exterior( obj )
            value = ~obj.interior;
        end
        
        function value = get.surface( obj )
            value = bwperim( obj.interior );
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
            v = obj.voxels.copy_blank( false );
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
        
        function value = to_pde_mesh( obj )
            id_list = unique( obj.voxels.values );
            material_ids = nan( max( id_list ), 1 );
            material_ids( id_list ) = id_list;
            value = UniformVoxelMesh( obj.voxels, material_ids );
        end
        
        function value = to_array( obj )
            value = obj.interior;
        end
        
        function value = to_table( obj )
            value = list2table( ...
                { 'count' }, ...
                { obj.count } ...
                );
        end
        
        function write( obj, output_files )
            output_files.write_array( obj.NAME, obj.to_array() );
            output_files.write_table( obj.NAME, obj.to_table() );
        end
    end
    
    methods ( Access = public, Static )
        function name = NAME()
            name = string( mfilename( 'class' ) );
        end
    end
    
    properties ( Access = private )
        casting Casting
        desired_element_count(1,1) double
        voxels Voxels
    end
    
    methods ( Access = private )
        function obtain_inputs( obj )
            if ~isempty( obj.results )
                casting_key = ProcessKey( Casting.NAME );
                obj.casting = obj.results.get( casting_key );
            end
            assert( ~isempty( obj.casting ) );
            
            if ~isempty( obj.options )
                loc = 'processes.mesh.element_count';
                obj.desired_element_count = obj.options.get( loc );
            end
            assert( ~isempty( obj.desired_element_count ) );
        end
        
        function prepare_voxels( obj )
            obj.printf( "Meshing...\n" );
            obj.voxels = Voxels( ...
                obj.desired_element_count, ...
                obj.casting.envelope, ...
                0 ...
                );
            obj.voxels.paint( obj.casting.fv, 1 );
        end
    end
    
end

