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

