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
        
        
        function assign_uniform_external_boundary_id( obj, id )
            
            obj.external_interfaces.assign_uniform_id( id );
            
        end
        
        
        function assign_external_boundary_id( obj, id, interface_ids )
            
            obj.external_interfaces.assign_id( id, interface_ids );
            
        end
        
        
        function build( obj )
            
            obj.material_ids = obj.get_material_ids();
            obj.voxels = obj.paint_voxels();
            volumes = obj.voxels.element_volume .* ones( obj.voxels.element_count, 1 );
            obj.elements = modeler.mesh.Elements( ...
                obj.voxels.array( : ), ...
                obj.material_ids( obj.voxels.array( : ) ), ...
                volumes ...
                );
            
            % external
            element_ids = cell2mat( obj.voxels.get_external_elements() );
            areas = obj.voxels.interface_area .* ones( size( element_ids ) );
            distances = 0.5 .* obj.voxels.scale .* ones( size( element_ids ) );
            obj.external_interfaces = modeler.mesh.ExternalInterfaces( ...
                obj.elements, ...
                element_ids, ...
                areas, ...
                distances ...
                );
            
            % internal
            element_ids = obj.voxels.get_neighbor_pairs();
            areas = obj.voxels.interface_area .* ones( size( element_ids, 1 ), 1 );
            distances = obj.voxels.interface_area .* ones( size( element_ids ) );
            obj.internal_interfaces = modeler.mesh.InternalInterfaces( ...
                obj.elements, ...
                element_ids, ...
                areas, ...
                distances ...
                );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        dimension_count
        desired_element_count
        component_list
        voxels
        material_ids
        
        elements
        internal_interfaces
        external_interfaces
        
    end
    
    
    methods ( Access = private )
        
        function ids = get_material_ids( obj )
            
            ids = [ obj.component_list.id ];
            
        end
        
        
        function voxels = paint_voxels( obj )
            
            envelope = obj.unify_envelopes();
            voxels = mesh.Voxels( obj.desired_element_count, envelope );
            for i = 1 : numel( obj.component_list )
                
                c = obj.component_list( i );
                voxels.paint( c.get_fv(), i );
                
            end
            
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


