classdef (Sealed) PartingDirection < handle
    
    properties ( Access = private )
        
        parting_directions
        index
        done
        
    end
    
    methods ( Access = public )
        
        function obj = PartingDirection( parting_directions )
            
            % todo validation goes here
            obj.parting_directions = parting_directions;
            obj.index = 1;
            obj.done = false;
            
        end
        
        
        function done = is_done( obj )
            
            done = obj.done;
            
        end
        
        
        function move_to_next( obj )
            
            if obj.done
                return;
            end
            
            obj.index = obj.index + 1;
            if obj.index > length( obj.parting_directions )
                obj.done = true;
            end
            
        end
        
        
        function value = get( obj )
            
            if isempty( obj.parting_directions )
                value = obj.parting_directions;
            else
                value = obj.parting_directions( obj.index );
            end
            
        end
        
    end
    
end

