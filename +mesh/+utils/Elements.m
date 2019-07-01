classdef Elements < handle
    
    properties ( Access = public )
        
        count(1,1) uint64 {mustBePositive} = 1
        component_ids(:,1) uint64 {mustBePositive} = 1
        material_ids(:,1) uint64 {mustBePositive} = 1
        volumes(:,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1
        
    end
    
    
    methods ( Access = public )
        
        function obj = Elements( varargin )
            
            if nargin == 0
                return;
            end
            
            if nargin < 3 || 3 < nargin
                assert( false )
            end
            
            component_ids = varargin{ 1 };
            material_ids = varargin{ 2 };
            volumes = varargin{ 3 };
            
            assert( numel( component_ids ) == numel( material_ids ) );
            assert( numel( component_ids ) == numel( volumes ) );
            
            obj.count = numel( component_ids );
            obj.component_ids = component_ids;
            obj.material_ids = material_ids;
            obj.volumes = volumes;
            
        end
        
        
        function count = get_material_id_count( obj )
            
            count = numel( obj.get_unique_material_ids() );
            
        end
        
        
        function ids = get_unique_material_ids( obj )
            
            ids = unique( obj.material_ids );
            
        end
        
    end
    
end

