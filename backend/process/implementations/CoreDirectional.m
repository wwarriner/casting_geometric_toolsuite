classdef (Sealed) CoreDirectional < Core    
    
    properties ( Access = public, Constant )
        
        NAME = 'core_directional'
        
    end
    
    
    methods ( Access = public )
        
        function obj = CoreDirectional( varargin )
            
            obj = obj@Core( varargin{ : } );
            
        end
        
    end
    
    
    methods ( Access = protected )
        
        function core_space = create_array( obj )
            
            core_space = map_slice_transform( ...
                @(slices)obj.core_slice_transform( slices ), ...
                { obj.mesh.exterior, obj.undercuts.array }, ...
                obj.DEFAULT_PARTING_DIMENSION ...
                );
            core_space( obj.mesh.interior ) = 0;
            
        end
        
    end
    
    
    methods ( Access = private )
        
        function core_slice = core_slice_transform( obj, slices )
            
            % 1 is core_space
            % 2 is undercut
            core_slice = slices{ 1 };
            distances = bwdistgeodesic( ...
                core_slice, ...
                logical( slices{ 2 } ), ...
                'quasi-euclidean' ...
                );
            core_slice( distances > obj.get_threshold() ) = 0;
            
        end
        
    end
    
end

