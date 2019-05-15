classdef (Sealed) CavityThinWall < ThinWall
    
    methods ( Access = public )
        
        function obj = CavityThinWall( varargin )
            
            obj = obj@ThinWall( varargin{ : } );
            obj.set_region( ThinWall.CAVITY );
            
            if nargin == 0; return; end
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function name = NAME()
            
            name = mfilename( 'class' );
            
        end
        
    end
    
end

