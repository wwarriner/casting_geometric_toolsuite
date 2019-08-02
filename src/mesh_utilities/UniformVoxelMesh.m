classdef UniformVoxelMesh < MeshInterface
    
    properties
        default_body_id(1,1) uint32 {mustBeNonnegative} = 1
    end
    
    properties ( SetAccess = private, Dependent )
        connectivity%(:,1) uint32 {mustBePositive}
        count%(1,1) uint32
        volumes%(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
    end
    
    methods
        % @voxels is a Voxels object
        % @material_ids is a vector with a material_id at each body_id
        % index, and zero elsewhere.
        function obj = UniformVoxelMesh( voxels, material_ids )
            material_values = material_ids( voxels.values( : ) );
            assert( ~any( material_values == 0, 'all' ) );
            elements = Elements( ...
                voxels.values( : ), ...
                material_values, ...
                voxels.element_volume .* ones( voxels.element_count, 1 ) ...
                );
            % external
            element_ids = cell2mat( voxels.external_elements );
            areas = voxels.element_area .* ones( size( element_ids ) );
            distances = 0.5 .* voxels.scale .* ones( size( element_ids ) );
            external_interfaces = ExternalInterfaces( ...
                elements, ...
                element_ids, ...
                areas, ...
                distances ...
                );
            % internal
            element_ids = voxels.neighbor_pairs;
            areas = voxels.element_area .* ones( size( element_ids, 1 ), 1 );
            distances = 0.5 .* voxels.scale .* ones( size( element_ids ) );
            internal_interfaces = InternalInterfaces( ...
                elements, ...
                element_ids, ...
                areas, ...
                distances ...
                );
            
            obj.shape = voxels.shape;
            obj.elements = elements;
            obj.external_interfaces = external_interfaces;
            obj.internal_interfaces = internal_interfaces;
        end
        
        function value = get.connectivity( obj )
            value = obj.internal_interfaces.element_ids;
        end
        
        function value = get.count( obj )
            value = obj.elements.count;
        end
        
        function value = get.volumes( obj )
            value = obj.elements.volumes;
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
        
        function field = reshape( obj, values )
            field = reshape( values, obj.shape );
        end
    end
    
    properties ( Access = private )
        shape(3,1) uint32 {mustBePositive}
        elements Elements
        internal_interfaces InternalInterfaces
        external_interfaces ExternalInterfaces
        desired_element_count(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1.0
    end
    
end


