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
            
            if obj.has_gravity_direction() && obj.is_orientation_dependent()
                pk = ProcessKey( ...
                    obj.NAME, ...
                    obj.parting_dimension, ...
                    obj.gravity_direction ...
                    );
            elseif obj.is_orientation_dependent()
                pk = ProcessKey( ...
                    obj.NAME, ...
                    obj.parting_dimension ...
                    );
            else
                pk = ProcessKey( ...
                    obj.NAME ...
                    );
            end
            name = pk.to_string();
            
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

