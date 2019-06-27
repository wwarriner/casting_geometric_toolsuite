classdef UniformVoxelMesh < modeler.mesh.MeshInterface
    
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
    
    
    % base class implementations
    % see base class definition for documentation
    methods ( Access = public )
        
        function add_component( obj, component )
            
            obj.component_list = [ obj.component_list component ];
            
        end
        
        
        function assign_default_external_boundary_id( obj, id )
            
            obj.default_external_boundary_id = id;
            
        end
        
        
        function assign_external_boundary_id( obj, id, interface_ids )
            
            obj.external_boundary_id_list( obj, id, interface_ids );
            
        end
        
        
        function build( obj )
            
            envelope = obj.unify_envelopes();
            obj.voxels = mesh.Voxels( obj.desired_element_count, envelope );
            for i = 1 : numel( obj.component_list )
                
                component = obj.component_list( i );
                obj.voxels.paint_fv( component.get_fv(), component.id );
                
            end
            
            % internal
            external_boundary_indices = obj.determine_external_boundary_indices( ...
                obj.dimension_count, ...
                obj.element_count, ...
                obj.strides ...
                );
            obj.connectivity_in = obj.determine_internal_connectivity( ...
                obj.element_count, ...
                obj.dimension_count, ...
                obj.strides, ...
                external_boundary_indices ...
                );
            obj.interface_count_in = size( obj.connectivity_in, 1 );
            obj.interface_areas_in = obj.determine_interface_areas( ...
                obj.interface_count_in, ...
                obj.interface_area ...
                );
            obj.distances_fwd_in = obj.determine_distances( ...
                obj.interface_count_in, ...
                obj.half_scale ...
                );
            obj.distances_bwd_in = obj.determine_distances( ...
                obj.interface_count_in, ...
                obj.half_scale ...
                );
            obj.is_boundary_in = obj.determine_internal_boundaries( ...
                obj.connectivity_in, ...
                obj.material_ids ...
                );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        dimension_count
        desired_element_count
        voxels
        
        connectivity_in
        interface_count_in
        interface_areas_in
        distances_fwd_in
        distances_bwd_in
        is_boundary_in
        
        material_ids
        
        half_scale
        interface_area
        element_volume
        
        component_list
        
    end
    
    
    methods ( Access = public, Static )
        
        function connectivity = determine_internal_connectivity( ...
                element_count, ...
                dimension_count, ...
                strides, ...
                is_external_boundary ...
                )
            
            base = true( element_count, dimension_count );
            for i = 1 : dimension_count
                base( is_external_boundary{ i }, i ) = false;
            end
            connectivity = spdiags2( ...
                base, ...
                strides, ...
                element_count, ...
                element_count ...
                );
            [ lhs, rhs ] = find( connectivity );
            connectivity = [ lhs rhs ];
            
        end
        
        
        function interface_areas = determine_interface_areas( ...
                interface_count, ...
                interface_area ...
                )
            
            interface_areas = interface_area .* ones( interface_count, 1 );
            
        end
        
        
        function distances = determine_distances( ...
                interface_count, ...
                separation_length ...
                )
            
            distances = separation_length .* ones( interface_count, 1 );
            
        end
        
        
        function all = determine_connectivity( ...
                external_boundaries, ...
                dimension_count, ...
                element_count, ...
                strides ...
                )
            
            % external
            external_count = 0;
            for i = 1 : 2 * dimension_count
                
                external_count = external_count + numel( external_boundaries{ i } );
                
            end
            external = zeros( external_count, 2 );
            finish = 0;
            for i = 1 : 2 * dimension_count
                
                start = finish + 1;
                finish = start + numel( external_boundaries{ i } ) - 1;
                external( start : finish, 2 ) = external_boundaries{ i };
                
            end
            
            % internal
            base = true( element_count, dimension_count );
            for i = 1 : dimension_count
                
                base( external_boundaries{ i }, i ) = false;
                
            end
            connectivity = spdiags2( ...
                base, ...
                strides, ...
                element_count, ...
                element_count ...
                );
            [ lhs, rhs ] = find( connectivity );
            internal = [ lhs rhs ];
            all = [ internal; external ];
            
        end
        
        
        function boundaries = determine_internal_boundaries( ...
                connectivity, ...
                material_ids ...
                )
            
            boundaries = material_ids( connectivity( :, 1 ) ) ....
                == material_ids( connectivity( :, 2 ) );
            
        end
        
        
        function indices = determine_external_boundary_indices( ...
                dimension_count, ...
                element_count, ...
                strides ...
                )
            
            if dimension_count == 1
                indices = { 1, 1 };
                return;
            end
            
            augmented_strides = [ strides( : ); element_count ];
            
            bases = cell( dimension_count, 1 );
            for i = 1 : dimension_count
                
                current_stride = augmented_strides( i );
                next_stride = augmented_strides( i + 1 );
                order = 1 : dimension_count;
                order = [ order( order == i ) order( order ~= i ) ];
                bases{ i } = permute( 1 : current_stride : next_stride, order );
                
            end
            
            indices = cell( dimension_count, 1 );
            %indices = cell( 2 * dimension_count, 1 );
            for i = 1 : dimension_count
                
                order = 1 : dimension_count;
                order = order( order ~= i );
                inds = 0;
                for j = 1 : numel( order )
                    
                    inds = inds + bases{ order( j ) };
                    
                end
                inds = inds( : ) - dimension_count + 2;
                indices{ i } = inds;
                %indices{ i + dimension_count } = element_count - inds;
                
            end
            
        end
        
    end
    
    
    methods ( Access = private )
        
        function envelope = unify_envelopes( obj )
            
            envelope = obj.component_list( 1 ).envelope.copy();
            for i = 2 : numel( obj.component_list )
                
                component = obj.component_list( 1 );
                envelope = envelope.union( component.envelope );
                
            end
            
        end
        
    end
    
end


