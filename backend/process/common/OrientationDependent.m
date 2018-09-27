classdef OrientationDependent < handle
    
    properties ( GetAccess = public, SetAccess = protected )
        
        parting_dimension
        gravity_direction
        
    end
    
    
    properties ( Access = public, Constant )
        
        DEFAULT_PARTING_DIMENSION = 3;
        DEFAULT_GRAVITY_DIRECTION = 'down';
        
    end
    
    
    methods ( Access = public )
        
        function obj = OrientationDependent()
            
            obj.parting_dimension = OrientationDependent.DEFAULT_PARTING_DIMENSION;
            obj.gravity_direction = OrientationDependent.DEFAULT_GRAVITY_DIRECTION;
            
        end
        
        
        function set_parting_dimension( obj, parting_dimension )
            
            obj.parting_dimension = parting_dimension;
            
        end
        
        
        function set_gravity_direction( obj, gravity_direction )
            
            obj.gravity_direction = gravity_direction;
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function orientation_dependent = is_orientation_dependent()
            
            orientation_dependent = false;
            
        end
        
        
        function gravity_direction = has_gravity_direction()
            
            gravity_direction = false;
            
        end
        
    end
    
end

