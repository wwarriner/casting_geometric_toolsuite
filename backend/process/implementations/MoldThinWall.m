classdef (Sealed) MoldThinWall < ThinWall
    
    properties ( Access = public, Constant )
        
        NAME = 'mold_thin_wall';
        
    end
    
    
    methods ( Access = public, Static )
        
        function obj = MoldThinWall( varargin )
            
            obj = obj@ThinWall( varargin{ : } );
            
            if nargin == 0; return; end
            
            obj.set_region( 'mold' );
            
        end
        
    end
    
end

