classdef UniformVoxelMesh < mesh.MeshInterface
    
    properties ( Access = public )
        default_component_id(1,1) uint64 {mustBeNonnegative} = 1
    end
    
    properties ( SetAccess = private, Dependent )
        connectivity
        count
        volumes
    end
    
    methods ( Access = public )
        
        % - material_id_array is an array of values representing materials
        % - scale is a finite double greater than zero indicating
        % the separation of voxels from center to center along any one axis
        function obj = UniformVoxelMesh( element_count )
            assert( isa( element_count, 'double' ) );
            assert( isscalar( element_count ) );
            assert( isfinite( element_count ) );
            assert( 0.0 < element_count );
            
            obj.dimension_count = 3;
            obj.desired_element_count = element_count;
        end
        
    end
    
    
    methods % getters
        
        function value = get.connectivity( obj )
            value = obj.internal_interfaces.element_ids;
        end
        
        function value = get.count( obj )
            value = obj.elements.count;
        end
        
        function value = get.volumes( obj )
            value = obj.elements.volumes;
        end
        
    end
    
    
    % base class implementations
    % see base class definition for documentation
    methods ( Access = public )
        
        function add_component( obj, component )
            obj.component_list = [ obj.component_list component ];
        end
        
        function build( obj )
            obj.material_ids = obj.get_material_ids();
            obj.voxels = obj.paint_voxels();
            obj.elements = mesh.utils.Elements( ...
                obj.voxels.values( : ), ...
                obj.material_ids( obj.voxels.values( : ) ), ...
                obj.voxels.element_volume .* ones( obj.voxels.element_count, 1 ) ...
                );
            % external
            element_ids = cell2mat( obj.voxels.external_elements );
            areas = obj.voxels.interface_area .* ones( size( element_ids ) );
            distances = 0.5 .* obj.voxels.scale .* ones( size( element_ids ) );
            obj.external_interfaces = mesh.utils.ExternalInterfaces( ...
                obj.elements, ...
                element_ids, ...
                areas, ...
                distances ...
                );
            % internal
            element_ids = obj.voxels.neighbor_pairs;
            areas = obj.voxels.interface_area .* ones( size( element_ids, 1 ), 1 );
            distances = 0.5 .* obj.voxels.scale .* ones( size( element_ids ) );
            obj.internal_interfaces = mesh.utils.InternalInterfaces( ...
                obj.elements, ...
                element_ids, ...
                areas, ...
                distances ...
                );
        end
        
        function assign_uniform_external_boundary_id( obj, id )
            obj.external_interfaces.assign_uniform_id( id );
        end
        
        function assign_external_boundary_id( obj, id, interface_ids )
            obj.external_interfaces.assign_id( id, interface_ids );
        end
        
        function values = apply_external_bc_fns( obj, fns )
            if isa( fns, 'function_handle' )
                fns = repmat( { fns }, [ obj.external_interfaces.bc_id_count 1 ] );
            end
            
            values = zeros( obj.external_interfaces.count, 1 );
            m_ids = obj.elements.material_ids( obj.external_interfaces.element_ids );
            m_id_list = obj.elements.material_id_list;
            bc_id_list = obj.external_interfaces.bc_id_list;
            for i = 1 : obj.external_interfaces.bc_id_count
                bc_id = bc_id_list( i );
                fn = fns{ i };
                for m_id = m_id_list( : ).'
                    locations = bc_id == obj.external_interfaces.boundary_ids & m_id == m_ids;
                    e_ids = obj.external_interfaces.element_ids( locations, : );
                    values( locations ) = fn( m_id, e_ids, obj.external_interfaces.distances( locations ), obj.external_interfaces.areas( locations ) );
                end
            end
            values = accumarray( obj.external_interfaces.element_ids, values, [ obj.elements.count, 1 ] );
        end
        
        function values = apply_internal_bc_fns( obj, fns )
            if isa( fns, 'function_handle' )
                fns = repmat( { fns }, [ obj.internal_interfaces.bc_id_count 1 ] );
            end
            
            values = zeros( obj.internal_interfaces.count, 1 );
            m_ids = sort( obj.elements.material_ids( obj.internal_interfaces.element_ids ), 2 );
            id_list = obj.internal_interfaces.bc_id_list;
            for i = 1 : obj.internal_interfaces.bc_id_count
                ids = id_list( i, : );
                fn = fns{ i };
                locations = all( m_ids == ids, 2 );
                e_ids = obj.internal_interfaces.element_ids( locations, : );
                values( locations ) = fn( ids, e_ids, obj.internal_interfaces.distances( locations, : ), obj.internal_interfaces.areas( locations ) );
            end
        end
        
        function values = apply_internal_interface_fns( obj, fn )
            values = fn( ...
                obj.internal_interfaces.element_ids, ...
                obj.internal_interfaces.distances, ...
                obj.internal_interfaces.areas ...
                );
        end
        
        % @apply_material_property_fn applies the material property
        % function or functions in @fns to the list of elements in the
        % mesh, returning a vector with the same number of elements as the
        % underlying mesh.
        % - @fns must be either a single function handle, applied uniformly
        % to all material ids, or a cell array of function handles, one per
        % material id in the mesh. Each function handle in @fns must be of
        % the form `values = fn( id, locations )` where id is a scalar
        % material id, locations is a logical vector indicating the
        % elements with that material id (for e.g. field lookup), and
        % values is a list of returns values of the same size as locations
        % assigned to @values in the appropriate elements.
        % - @values are the values of the applied function
        function values = apply_material_property_fn( obj, fns )
            if isa( fns, 'function_handle' )
                fns = repmat( { fns }, [ obj.elements.material_id_count 1 ] );
            end
            
            values = zeros( obj.elements.count, 1 );
            ids = obj.elements.material_id_list;
            for i = 1 : obj.elements.material_id_count
                id = ids( i );
                locations = obj.elements.material_ids == id;
                fn = fns{ i };
                values( locations ) = fn( id, locations );
            end
        end
        
    end
    
    
    % class specific methods
    methods ( Access = public )
        
        function field = reshape( obj, values )
            field = reshape( values, obj.voxels.shape );
        end
        
    end
    
    
    properties ( Access = private )
        dimension_count
        component_list
        voxels
        material_ids
        elements
        internal_interfaces
        external_interfaces
        desired_element_count
    end
    
    
    methods ( Access = private )
        
        function ids = get_material_ids( obj )
            id_list = [ obj.component_list.id ];
            ids = nan( max( id_list ), 1 );
            ids( id_list ) = id_list;
        end
        
        function voxels = paint_voxels( obj )
            envelope = obj.unify_envelopes();
            voxels = mesh.voxel.Voxels( ...
                obj.desired_element_count, ...
                envelope, ...
                obj.default_component_id ...
                );
            for i = 1 : numel( obj.component_list )
                c = obj.component_list( i );
                voxels.paint( c.fv, c.id );
            end
            assert( ~any( voxels.values == 0, 'all' ) );
        end
        
        function envelope = unify_envelopes( obj )
            envelope = obj.component_list( 1 ).envelope.copy();
            for i = 2 : numel( obj.component_list )
                component = obj.component_list( 1 );
                envelope = envelope.union( component.envelope );
            end
        end
        
    end
    
end


