classdef (Abstract) Process < UserInterface & handle
    
    methods ( Abstract )
        value = write( obj, files );
    end
    
    methods
        function obj = Process( results, settings )
            if nargin == 0; return; end
            obj.results = results;
            obj.settings = settings;
        end
        
        function run( obj )
            if ~isempty( obj.settings )
                obj.settings.apply( obj );
            end
            obj.check_settings();
            if ~isempty( obj.results )
                obj.update_dependencies();
            end
            obj.run_impl();
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
        run_impl( obj )
    end
    
end

