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
            
            obj.index = obj.index + 1;
            if obj.index > length( obj.gravity_directions )
                obj.index = 1;
                obj.done = true;
            end
            
        end
        
        
        function is = is_gravity_dependent( obj )
            
            is = ( obj.gravity_directions{ 1 } > 0 );
            
        end
        
        
        function value = get( obj )
            
            value = obj.gravity_directions{ obj.index };
            
        end
        
        
        function name = append_to_name( obj, name )
            
            if obj.is_gravity_dependent()
                name = [ name '_' obj.get() ];
            end
            
        end
        
    end
    
end

