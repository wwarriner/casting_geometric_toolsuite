classdef (Sealed) MoldThinWall < ThinWall
    
    properties ( Access = public, Constant )
        
        NAME = 'mold_thin_wall';
        
    end
    
    
    methods ( Access = public )
        
        function obj = MoldThinWall( varargin )
            
            obj = obj@ThinWall( varargin{ : } );
            obj.set_region( 'mold' );
            
            if nargin == 0; return; end
            
        end
        
    end
    
end

