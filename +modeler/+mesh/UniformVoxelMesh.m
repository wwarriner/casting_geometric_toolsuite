classdef UniformVoxelMesh < modeler.mesh.MeshInterface
    
    methods ( Access = public )
        
        % material_id_array is an array of values representing materials
        % - element_separation is a finite double greater than zero indicating
        % the separation of voxels from center to center along an axis
        function obj = UniformVoxelMesh( ...
                material_id_array, ...
                element_separation ...
                )
            
            assert( isnumeric( material_id_array ) );
            
            assert( isa( element_separation, 'double' ) );
            assert( isfinite( element_separation ) );
            assert( 0.0 < element_separation );
            
            if isvector( material_id_array )
                obj.dimension_count = 1;
            else
                obj.dimension_count = ndims( material_id_array );
            end
            obj.element_count = numel( material_id_array );
            obj.shape = size( material_id_array );
            if obj.dimension_count == 1
                obj.strides = 1;
            else
                obj.strides = [ 1 cumprod( obj.shape( 1 : end - 1 ) ) ];
            end
            
            % get all pairs of neighbors (connectivity)
            % get all indices touching exterior along each axis
            %  make into pairs with 0 (0,each)
            %  append to pairs of neighbors
            %  
            % convert connectivity to material ids
            % get indices of those which are not equal
            % that is interior boundaries
            
            obj.external_boundary_ids = obj.determine_external_boundary_indices( ...
                obj.dimension_count, ...
                obj.element_count, ...
                obj.strides ...
                );
            base = true( obj.element_count, obj.dimension_count );
            for i = 1 : obj.dimension_count
                
                base( inds{ i }, i ) = false;
                
            end
            connectivity = spdiags2( ...
                base, ...
                obj.strides, ...
                obj.element_count, ...
                obj.element_count ...
                );
            [ obj.lhs_connectivity, obj.rhs_connectivity ] = find( connectivity );
            
            obj.material_ids = material_id_array( : );
            
            obj.element_separation = element_separation;
            obj.half_separation = 0.5 * obj.element_separation;
            obj.interface_area = element_separation .^ 2;
            obj.element_volume = element_separation .^ 3;
            
        end
        
    end
    
    
    % base class implementations
    % see base class definition for documentation
    methods ( Access = public )
        
        function count = get_dimension_count( obj )
            
            count = obj.dimension_count;
            
        end
        
        
        function count = get_count( obj )
            
            count = obj.element_count;
            
        end
        
        
        function [ lhs, rhs ] = get_connectivity( obj )
            
            lhs = obj.lhs_connectivity;
            rhs = obj.rhs_connectivity;
            
        end
        
        
        function ids = get_unique_material_ids( obj )
            
            ids = unique( obj.get_material_ids() );
            
        end
        
        
        function ids = get_material_ids( obj )
            
            ids = obj.material_ids;
            
        end
        
        
        function ids = get_external_boundary_ids( obj )
            
            ids = obj.external_boundary_ids;
            
        end
        
        
        function ids = get_internal_boundary_ids( obj )
            
            ids = obj.internal_boundary_ids;
            
        end
        
        
        function [ lhs, rhs ] = get_distances( obj )
            
            [ lhs, rhs ] = obj.get_connectivity();
            lhs = obj.half_separation .* ones( size( lhs ) );
            rhs = obj.half_separation .* ones( size( rhs ) );
            
        end
        
        
        function areas = get_interface_areas( obj )
            
            lhs = obj.get_connectivity();
            areas = obj.interface_area .* ones( size( lhs ) );
            
        end
        
        
        function volumes = get_element_volumes( obj )
            
            volumes = obj.element_volume .* ones( obj.element_count, 1 );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        dimension_count
        element_count
        shape
        strides
        
        lhs_connectivity
        rhs_connectivity
        
        material_ids
        external_boundary_ids
        internal_boundary_ids
        
        element_separation
        half_separation
        interface_area
        element_volume
        
    end
    
    
    methods ( Access = public, Static )
        
        function indices = determine_external_boundary_indices( ...
                dimension_count, ...
                element_count, ...
                strides ...
                )
            
            if dimension_count == 1
                indices = { 1 };
                return;
            end
            
            ec = element_count;
            augmented_strides = [ strides( : ); ec ];
            
            bases = cell( dimension_count, 1 );
            for i = 1 : dimension_count
                
                current_stride = augmented_strides( i );
                next_stride = augmented_strides( i + 1 );
                order = 1 : dimension_count;
                order = [ order( order == i ) order( order ~= i ) ]; 
                bases{ i } = permute( 1 : current_stride : next_stride, order );
                
            end
            
            indices = cell( dimension_count, 1 );
            for i = 1 : dimension_count
                
                order = 1 : dimension_count;
                order = order( order ~= i );
                inds = 0;
                for j = 1 : numel( order )
                    
                    inds = inds + bases{ order( j ) };
                    
                end
                indices{ i } = inds( : ) - dimension_count + 2;
                
            end
            
        end
        
    end
    
end


