classdef (Abstract) Process < UserInterface & handle
    
    properties ( SetAccess = public )
        % Properties intended to be changed by JSON interface should be in a
        % block like this in subclasses. The run() method will automatically
        % apply settings with the exact same name as the property here. The
        % properties should be located at processes.<ProcessName>.<PropertyName>
    end
    
    methods ( Abstract )
        value = write( obj, files );
    end
    
    methods
        function obj = Process( results, settings )
            % signature of subclasses will generally be:
            % obj = obj@Process( varargin{ : } );
            obj.check_errors_early();
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
        
        function value = to_table( obj )
            opts.pre = obj.NAME;
            value = append_to_variable_names( obj.to_table_impl(), opts );
        end
    end
    
    methods ( Static )
        function check_errors_early()
            % NO OP
        end
    end
    
    methods ( Abstract, Static )
        name = NAME(); % MUST be implemented as
        %{
        function name = NAME()
            name = string( mfilename( 'class' ) );
        end
        %}
    end
    
    properties ( Access = protected )
        results
        settings
    end
    
    methods ( Abstract, Access = protected )
        check_settings( obj ) % Checks whether settings are valid.
        update_dependencies( obj ) % Gets any dependencies from results object.
        run_impl( obj ) % Domain-specific code.
        to_table_impl( obj ) % Implementation of domain-specific tabular data.
    end
    
end

