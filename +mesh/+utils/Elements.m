classdef Elements < handle
    
    properties ( Access = public )
        component_ids(:,1) uint64 {mustBePositive} = 1
        material_ids(:,1) uint64 {mustBePositive} = 1
        volumes(:,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1
    end
    
    
    properties ( GetAccess = public, Dependent )
        count
        material_id_count
        material_id_list
    end
    
    
    methods ( Access = public )
        
        function obj = Elements( component_ids, material_ids, volumes )
            if nargin == 0
                return;
            end
            
            assert( numel( component_ids ) == numel( material_ids ) );
            assert( numel( component_ids ) == numel( volumes ) );
            
            obj.component_ids = component_ids;
            obj.material_ids = material_ids;
            obj.volumes = volumes;
        end
        
    end
    
    
    methods % getters
        
        function value = get.count( obj )
            value = numel( obj.component_ids );
        end
        
        function value = get.material_id_count( obj )
            value = numel( obj.material_id_list );
        end
        
        function value = get.material_id_list( obj )
            value = unique( obj.material_ids );
        end
        
    end
    
end

