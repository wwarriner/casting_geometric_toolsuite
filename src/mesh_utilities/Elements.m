classdef Elements < handle
    
    properties ( Access = public )
        body_ids(:,1) uint32 {mustBePositive} = 1
        material_ids(:,1) uint32 {mustBePositive} = 1
        volumes(:,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1
    end
    
    properties ( Dependent )
        count
        material_id_count
        material_id_list
    end
    
    methods
        function obj = Elements( body_ids, material_ids, volumes )
            if nargin == 0
                return;
            end
            
            assert( numel( body_ids ) == numel( material_ids ) );
            assert( numel( body_ids ) == numel( volumes ) );
            
            obj.body_ids = body_ids;
            obj.material_ids = material_ids;
            obj.volumes = volumes;
        end
        
        function value = get.count( obj )
            value = uint32( numel( obj.body_ids ) );
        end
        
        function value = get.material_id_count( obj )
            value = uint32( numel( obj.material_id_list ) );
        end
        
        function value = get.material_id_list( obj )
            value = unique( obj.material_ids );
        end
    end
    
end

