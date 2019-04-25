classdef (Sealed) GravityDirection < handle
    
    properties ( Access = private )
        
        gravity_directions
        index
        done
        
    end
    
    methods ( Access = public )
        
        function obj = GravityDirection( gravity_directions )
            
            % todo validation goes here
            obj.gravity_directions = gravity_directions;
            obj.index = 1;
            obj.done = false;
            
        end
        
        
        function reset( obj )
            
            obj.done = false;
            obj.index = 1;
            
        end
        
        
        function done = is_done( obj )
            
            done = obj.done;
            
        end
        
        
        function move_to_next( obj )
            
            if obj.done
                return;
            end
            
            obj.index = obj.index + 1;
            if obj.index > length( obj.gravity_directions )
                obj.done = true;
            end
            
        end
        
        
        function value = get( obj )
            
            if isempty( obj.gravity_directions )
                value = obj.gravity_directions;
            else
                value = obj.gravity_directions{ obj.index };
            end
            
        end
        
    end
    
end

