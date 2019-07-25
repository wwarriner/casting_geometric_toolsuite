classdef (Abstract) Process < UserInterface & handle
    
    methods ( Abstract, Access = public )
        run( obj );
        value = write( obj, files );
    end
    
    methods
        function obj = Process( results, options )
            if nargin == 0; return; end
            obj.results = results;
            obj.options = options;
        end
    end
    
    methods ( Abstract, Static )
        name = NAME(); % MUST be implemented as
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

