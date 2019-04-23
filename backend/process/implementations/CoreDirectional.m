classdef (Sealed) CoreDirectional < Core
    
    methods ( Access = public )
        
        function obj = CoreDirectional( varargin )
            
            obj = obj@Core( varargin{ : } );
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function name = NAME()
            
            name = mfilename( 'class' );
            
        end
        
    end
    
    
    methods ( Access = protected )
        
        function core_space = create_array( obj )
            
            images{ obj.CORE_SPACE_INDEX } = obj.mesh.exterior;
            images{ obj.UNDERCUT_INDEX } = obj.undercuts.array;
            core_space = map_slice_transform( ...
                @(slices)obj.core_slice_transform( slices ), ...
                images, ...
                obj.DEFAULT_PARTING_DIMENSION ...
                );
            core_space( obj.mesh.interior ) = 0;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        CORE_SPACE_INDEX = 1;
        UNDERCUT_INDEX = 2;
        
    end
    
    
    methods ( Access = private )
        
        function core_slice = core_slice_transform( obj, slices )
            
            % 1 is core_space
            % 2 is undercut
            core_slice = slices{ obj.CORE_SPACE_INDEX };
            distances = bwdistgeodesic( ...
                core_slice, ...
                logical( slices{ obj.UNDERCUT_INDEX } ), ...
                'quasi-euclidean' ...
                );
            core_slice( distances > obj.get_threshold() ) = 0;
            
        end
        
    end
    
end

