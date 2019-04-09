classdef (Sealed) CavityThinWall < ThinWall
    
    properties ( Access = public, Constant )
        
        NAME = 'cavity_thin_wall';
        
    end
    
    
    methods ( Access = public )
        
        function obj = CavityThinWall( varargin )
            
            obj = obj@ThinWall( varargin{ : } );
            obj.set_region( 'cavity' );
            
            if nargin == 0; return; end
            
        end
        
    end
    
end

