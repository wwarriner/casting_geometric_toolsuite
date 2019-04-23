classdef (Sealed) CoreIsotropic < Core
    
    methods ( Access = public )
        
        function obj = CoreIsotropic( varargin )
            
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
            
            core_space = obj.mesh.exterior;
            distances = bwdistgeodesic( ...
                core_space, ...
                logical( obj.undercuts.array ), ...
                'quasi-euclidean' ...
                );
            core_space( distances > obj.get_threshold() ) = 0;
            core_space( obj.mesh.interior ) = 0;
            
        end
        
    end
    
end

