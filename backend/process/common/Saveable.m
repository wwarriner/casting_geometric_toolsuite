classdef Saveable < handle
    
    methods ( Access = public )
        
        function save_obj( obj, path, name )
            
            if nargin < 3
                name = [];
            end
            
            save( fullfile( path, name ), 'obj' );
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function obj = load_obj( path )
            
            s = load( path );
            obj = s.obj;
            
        end
        
    end
    
end

