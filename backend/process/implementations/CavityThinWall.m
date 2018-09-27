classdef (Sealed) CavityThinWall < ThinWall
    
    properties ( Access = public, Constant )
        
        NAME = 'cavity_thin_wall';
        
    end
    
    
    methods ( Access = public, Static )
        
        function obj = CavityThinWall( varargin )
            
            obj = obj@ThinWall( varargin{ : } );
            
            if nargin == 0; return; end
            
            obj.set_region( 'cavity' );
            
        end
        
    end
    
end

