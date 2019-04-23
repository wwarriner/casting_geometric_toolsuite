classdef Process < UserInterface & Output & OrientationDependent & handle
    
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
            
            pk = ProcessKey( ...
                obj.NAME, ...
                obj.parting_dimension, ...
                obj.gravity_direction ...
                );
            name = pk.get_key();
            
        end
        
    end
    
    
    methods ( Access = public, Static, Abstract )
        
        name = NAME(); % implement as
        %{
        function name = NAME()
            
            [ ~, name ] = fileparts( mfilename( 'full' ) );
            
        end
        %}
        
    end
    
    
    properties ( Access = protected )
        
        results
        options
        
    end
    
end

