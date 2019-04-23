classdef (Sealed) MoldThinWall < ThinWall
    
    methods ( Access = public )
        
        function obj = MoldThinWall( varargin )
            
            obj = obj@ThinWall( varargin{ : } );
            obj.set_region( 'mold' );
            
            if nargin == 0; return; end
            
        end
        
    end
    
    
    methods ( Access = private )
        
        function name = NAME()
            
            name = mfilename( 'class' );
            
        end
        
    end
    
end

