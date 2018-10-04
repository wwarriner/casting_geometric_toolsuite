classdef Process < UserInterface & Output & OrientationDependent & handle
    
    properties ( Access = public, Constant, Abstract )
        
        NAME
        
    end
    
    
    methods ( Access = public, Abstract )
        
        run( obj );
        
    end
    
    
    methods ( Access = public )
        
        function obj = Process( results, options )
            
            if nargin == 0; return; end
            obj.results = results;
            obj.options = options;
            
        end
        
        
        function name = get_storage_name( obj )
            
            name = obj.NAME;
            if obj.is_orientation_dependent()
                parting_dimension_str = num2str( int64( obj.parting_dimension ), '%d' );
                name = strjoin( { name, parting_dimension_str }, '_' );
            end
            if obj.has_gravity_direction()
                name = strjoin( { name, obj.gravity_direction }, '_' );
            end
            
        end
        
    end
    
    
    methods ( Access = public, Static, Abstract )
        
        dependencies = get_dependencies();
        
    end
    
    
    properties ( Access = protected )
        
        results
        options
        
    end
    
end

