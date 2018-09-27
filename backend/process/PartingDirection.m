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
            
            obj.index = obj.index + 1;
            if obj.index > length( obj.parting_directions )
                obj.index = 1;
                obj.done = true;
            end
            
        end
        
        
        function is = is_orientation_dependent( obj )
            
            is = ( obj.parting_directions( 1 ) > 0 );
            
        end
        
        
        function value = get( obj )
            
            value = obj.parting_directions( obj.index );
            
        end
        
        
        function name = append_to_name( obj, name )
            
            if obj.is_orientation_dependent()
                name = [ name '_' num2str( obj.get() ) ];
            end
            
        end
        
    end
    
end

