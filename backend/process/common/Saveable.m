classdef Saveable < handle
    
    methods ( Access = public )
        
        function save_obj( obj, path, name )
            
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

