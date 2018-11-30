classdef (Sealed) ComponentDelta < handle
    
    properties ( GetAccess = public, SetAccess = private )
        %% inputs
        current_component
        revised_component
        desired_element_count
        
        %% outputs
        % delta has four values, see public constant properties below
        delta
        shared_envelope
        
        removed_volume
        added_volume
        unchanged_volume
        
    end
    
    
    properties ( Access = public, Constant )
        
        NAME = 'comparison'
        EXTERIOR = 0;
        CURRENT_VALUE = 1;
        REVISED_VALUE = 2;
        % COMMON_VALUE = get_shared_value();
        
    end
    
    
    methods ( Access = public )
        
        function obj = ComponentDelta( ...
                current_component, ...
                revised_component, ...
                desired_mesh_element_count ...
                )
            
            obj.current_component = current_component;
            obj.revised_component = revised_component;
            obj.desired_element_count = desired_mesh_element_count;
            obj.run();
            
        end
        
        
        function run( obj )
            %% Mesh both components on a common mesh
            obj.shared_envelope = MeshEnvelope( merge_fv( ...
                obj.current_component.fv, ...
                obj.revised_component.fv ...
                ) );
            current_mesh = Mesh();
            current_mesh.legacy_run( ...
                obj.current_component, ...
                obj.desired_element_count, ...
                obj.shared_envelope ...
                );
            revised_mesh = Mesh();
            revised_mesh.legacy_run( ...
                obj.revised_component, ...
                obj.desired_element_count, ...
                obj.shared_envelope ...
                );
            
            %% Compute delta
            obj.delta = obj.compute_delta( ...
                current_mesh.interior, ...
                revised_mesh.interior ...
                );
            
            %% Calculate statistics
            obj.removed_volume = obj.compute_volume( ...
                obj.delta, ...
                obj.CURRENT_VALUE, ...
                current_mesh.get_element_volume() ...
                );
            obj.added_volume = obj.compute_volume( ...
                obj.delta, ...
                obj.REVISED_VALUE, ...
                current_mesh.get_element_volume() ...
                );
            obj.unchanged_volume = obj.compute_volume( ...
                obj.delta, ...
                obj.get_shared_value(), ...
                current_mesh.get_element_volume() ...
                );
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function common_value = get_shared_value()
            
            assert( ComponentDelta.CURRENT_VALUE ~= ComponentDelta.REVISED_VALUE );
            common_value = ComponentDelta.CURRENT_VALUE + ComponentDelta.REVISED_VALUE;
            
        end
        
    end
    
    
    methods ( Access = protected )
        
        function names = get_table_names( ~ )
            
            names = { ...
                'removed_volume', ...
                'added_volume', ...
                'unchanged_volume' ...
                };
            
        end
        
        
        function values = get_table_values( obj )
            
            values = [ ...
                obj.removed_volume, ...
                obj.added_volume, ...
                obj.unchanged_volume ...
                ];
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function delta = compute_delta( current_interior, revised_interior )
            
            delta = ...
                ( ComponentDelta.CURRENT_VALUE .* current_interior ) ...
                + ( ComponentDelta.REVISED_VALUE .* revised_interior );
            
        end
        
        
        function volume = compute_volume( delta, value, element_volume )
            
            volume = sum( delta( : ) == value ) .* element_volume;
            
        end
        
    end
    
end

