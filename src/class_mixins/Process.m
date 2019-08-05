classdef (Abstract) Process < UserInterface & handle
    
    methods ( Abstract, Access = public )
        run( obj );
        value = write( obj, files );
    end
    
    methods
        function obj = Process( results, settings )
            if nargin == 0; return; end
            obj.results = results;
            obj.settings = settings;
            if ~isempty( obj.settings )
                obj.settings.apply( obj );
            end
            obj.check_settings();
            obj.update_dependencies();
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
        settings
    end
    
    methods ( Abstract, Access = protected )
        check_settings( obj )
        update_dependencies( obj )
    end
    
end

