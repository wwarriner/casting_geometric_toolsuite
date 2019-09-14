classdef TetrahedralMesh < MeshInterface
    
    properties ( SetAccess = private, Dependent )
        connectivity%(:,1) uint32 {mustBePositive}
        count%(1,1) uint32
        volumes%(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        distances%(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
    end
    
    methods
        function obj = TetrahedralMesh()
            obj.canvas = BodyCanvas();
        end
        
        function add_body( obj, body )
            obj.canvas.add_body( body );
        end
        
        function generate( obj )
            material_ids = obj.canvas.material_ids;
            fv = obj.canvas.fv;
            max_volume = max( obj.canvas.volumes ) ./ ( 1000 .^ 3 );
            [ nodes_in, elements_in, external_faces_in ] = s2m( ...
                fv.vertices, ...
                fv.faces, ...
                0.35, ...
                max_volume / 100, ...
                'tetgen', ...
                obj.canvas.region_points ...
                );
            
            body_ids_in = elements_in( :, 5 );
            body_ids = body_ids_in;
            
            material_values = material_ids( body_ids );
            assert( ~any( material_values == 0, 'all' ) );
            
            a = nodes_in( elements_in( :, 1 ), : );
            b = nodes_in( elements_in( :, 2 ), : );
            c = nodes_in( elements_in( :, 3 ), : );
            d = nodes_in( elements_in( :, 4 ), : );
            volumes_in = abs( dot( a-d, cross( b-d, c-d, 2 ), 2 ) ) / 6.0;
            volumes_in = volumes_in ./ ( 1000 .^ 3 ); % m^3 <- mm^3;
            ee = Elements( body_ids, material_values, volumes_in );
            
            elements_in = elements_in( :, 1 : 4 );
            external_faces_in = external_faces_in( :, 1 : 3 );
            
            f1 = elements_in( :, [ 1 2 3 ] );
            f2 = elements_in( :, [ 1 2 4 ] );
            f3 = elements_in( :, [ 1 3 4 ] );
            f4 = elements_in( :, [ 2 3 4 ] );
            orig_faces = [ f1; f2; f3; f4 ];
            elems = repmat( ( 1 : size( elements_in, 1 ) ).', [ 4 1 ] );
            mats = repmat( material_values, [ 4 1 ] );
            
            SORT_DIM = 2;
            faces = sort( orig_faces, SORT_DIM, "ascend" );
            external_faces_sorted = sort( external_faces_in, SORT_DIM, "ascend" );
            is_ex_face = ismember( faces, external_faces_sorted, "rows" );
            
            external_faces_cell = containers.Map( ...
                "keytype", "double", ...
                "valuetype", "any" ...
                );
            prev_ex_mat_face = false( numel( mats ), 1 );
            duplicated = false( numel( mats ), 1 );
            for i = numel( material_ids ) : -1 : 1
                id = material_ids( i );
                is_ex_mat_face = is_ex_face & ( mats == id );
                
                ii = ismember( faces, faces( is_ex_mat_face, : ), "rows" );
                
                duplicated = duplicated | ( ii & ~is_ex_mat_face & prev_ex_mat_face );
                prev_ex_mat_face = prev_ex_mat_face | ii;
                external_faces_cell( id ) = orig_faces( is_ex_mat_face, : );
            end
            
            is_ex_face = is_ex_face( ~duplicated );
            faces = faces( ~duplicated, : );
            elems = elems( ~duplicated, : );
            
            ex_inds = find( is_ex_face );
            ex_elems = elems( ex_inds );
            
            [ ~, i ] = sortrows( faces );
            i = i( ~is_ex_face( i ) );
            in_inds_lhs = i( 1 : 2 : end );
            in_elems_lhs = elems( in_inds_lhs );
            in_inds_rhs = i( 2 : 2 : end );
            in_elems_rhs = elems( in_inds_rhs );
            assert( all( faces( in_inds_lhs, : ) == faces( in_inds_rhs, : ), "all" ) );
            
            areas = compute_triangle_areas( faces, nodes_in );
            
            orig_centroids = ( a + b + c + d ) / 4.0;
            centroids_in = repmat( orig_centroids, [ 4 1 ] );
            %centroids_in = centroids_in( ~duplicated, : );
            
            a = nodes_in( faces( :, 1 ), : );
            b = nodes_in( faces( :, 2 ), : );
            c = nodes_in( faces( :, 3 ), : );
            distances_in = abs( dot( a-centroids_in, cross( b-centroids_in, c-centroids_in, 2 ), 2 ) ) / 6.0;
            distances_in = 3.0 * distances_in ./ areas;
            
            distances_in = distances_in ./ 1000; % m <- mm;
            areas = areas ./ ( 1000 .^ 2 ); % m^2 <- mm^2;
            ex = ExternalInterfaces( ee, ex_elems, areas( ex_inds ), distances_in( ex_inds ) );
            in_elems = [ in_elems_lhs in_elems_rhs ];
            in_inds = [ in_inds_lhs in_inds_rhs ];
            in = InternalInterfaces( ee, in_elems, areas( in_inds_rhs ), distances_in( in_inds ) );
            
            obj.internal_interfaces = in;
            obj.external_interfaces = ex;
            obj.elements = ee;
            obj.centroids = orig_centroids;
            obj.nodes = nodes_in;
            obj.external_faces = external_faces_cell;
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
        
        function value = get.distances( obj )
            value = obj.internal_interfaces.distances;
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
                values( locations ) = fn( id, locations, obj.elements.volumes );
            end
        end
        
        function values = map( obj, fn )
            values = fn( obj.elements.material_ids );
        end
        
        function value = reduce( obj, fn )
            value = fn( obj.elements.material_ids );
        end
        
        function ph = plot_scalar_field( obj, axh, field, mask )
            if nargin < 4
                mask = ones( obj.count, 1 );
            end
            
            assert( isa( axh, "matlab.graphics.axis.Axes" ) );
            
            assert( isa( field, "double" ) );
            assert( isreal( field ) );
            assert( all( isfinite( field ) ) );
            assert( numel( field ) == obj.count );
            
            assert( islogical( mask ) );
            assert( numel( mask ) == obj.count );
            
            ph = scatter3( ...
                axh, ...
                obj.centroids( mask, 1 ), ...
                obj.centroids( mask, 2 ), ...
                obj.centroids( mask, 3 ), ...
                10, ...
                field( mask ), ...
                "filled" ...
                );
        end
        
        function ph = plot_mesh( obj, axh, ids )
            assert( isa( axh, "matlab.graphics.axis.Axes" ) );
            if nargin < 3
                ids = obj.elements.material_ids;
            end
            
            assert( isa( ids, "double" ) );
            assert( isreal( ids ) );
            assert( all( isfinite( ids ) ) );
            assert( ismember( ids, obj.canvas.material_ids ) );
            
            ph = gobjects( numel( ids ), 0 );
            for i = 1 : numel( ids )
                ph( i ) = patch( ...
                    axh, ...
                    "vertices", obj.nodes, ...
                    "faces", obj.external_faces( ids( i ) ) ...
                    );
            end
        end
        
        function f = create_interpolant( obj, field )
            assert( isa( field, "double" ) );
            assert( isreal( field ) );
            assert( all( isfinite( field ) ) );
            assert( numel( field ) == obj.count );
            
            f = scatteredInterpolant( ...
                obj.centroids( :, 1 ), ...
                obj.centroids( :, 2 ), ...
                obj.centroids( :, 3 ), ...
                field ...
                );
            f.ExtrapolationMethod = "none";
        end
    end
    
    properties ( Access = private )
        canvas BodyCanvas
        elements Elements
        internal_interfaces InternalInterfaces
        external_interfaces ExternalInterfaces
        centroids(:,3) double {mustBeReal,mustBeFinite}
        nodes(:,3) double {mustBeReal,mustBeFinite}
        external_faces containers.Map
    end
    
end

