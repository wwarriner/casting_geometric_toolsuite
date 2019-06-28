classdef Elements < handle
    
    properties ( Access = public )
        
        count(1,1) uint64 {mustBePositive} = 1
        component_ids(:,1) uint64 {mustBePositive} = 1
        material_ids(:,1) uint64 {mustBePositive} = 1
        volumes(:,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1
        
    end
    
    
    methods ( Access = public )
        
        function obj = Elements( component_ids, material_ids, volumes )
            
            assert( numel( component_ids ) == numel( material_ids ) );
            assert( numel( component_ids ) == numel( volumes ) );
            
            obj.count = numel( component_ids );
            obj.component_ids = component_ids;
            obj.material_ids = material_ids;
            obj.volumes = volumes;
            
        end
        
    end
    
end

