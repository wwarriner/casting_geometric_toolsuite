classdef Paraview < handle
    properties ( Access = public )
        casting_name(1,1) string = "UNKNOWN_NAME"
        input_folder(1,1) string
    end
    
    methods
        function obj = Paraview( settings )
            if nargin == 0
                return
            end
            
            obj.environment_file = settings.paraview.conda.environment_file;
            obj.environment_name = settings.paraview.conda.environment_name;
            obj.install_folder = settings.paraview.conda.install_folder;
            % have to normalize file separators and make absolute for ParaView
            obj.interface_folder = GetFullPath( settings.paraview.interface_folder, "/" );
            obj.script_file = settings.paraview.interface_script;
        end
        
        function set.input_folder( obj, value )
            % have to normalize file separators and make absolute for ParaView
            obj.input_folder = GetFullPath( value, "/" );
        end

        function set.casting_name( obj, value )
            obj.casting_name = value;
        end
        
        function open( obj )
            if ~obj.check_conda_installation()
                error( ...
                    "Conda is not installed." + newline ...
                    + "Please install from: https://www.anaconda.com/products/individual" + newline ...
                    );
            end
            if ~obj.check_environment_installation()
                fprintf( ...
                    "Unable to locate existing environment." + newline ...
                    + "If this is your first time using this software, this is expected." + newline ...
                    + "The environment will be installed now." + newline ...
                    + "This requires an activate internet connection." + newline ...
                    );
                obj.install_environment();
            end
            opened_ok = obj.open_paraview();
            if ~opened_ok
                fprintf( ...
                    "Unable to start paraview." + newline ...
                    + "Trying again to install the environment." + newline ...
                    );
                obj.install_environment();
                opened_ok = obj.open_paraview();
            end
            if ~opened_ok
                error( ...
                    "Unexpected error starting paraview." + newline ...
                    + "Please contact the software creator for support." + newline ...
                    );
            end
        end
        
        function installed = check_conda_installation( obj )
            fprintf( "Checking conda installation..." + newline );
            cmd = obj.build_activate_conda_command();
            cmd = cmd + " & conda --v";
            [~, result] = system( cmd );
            result = strip( result );
            out = regexp( result, "^conda [0-9]+\.[0-9]+\.[0-9]+$", "match" );
            installed = false;
            if ~isempty( out )
                installed = true;
            end
        end
    end
    
    properties ( Access = private )
        environment_file(1,1) string
        environment_name(1,1) string
        install_folder(1,1) string
        interface_folder(1,1) string
        script_file(1,1) string
    end
    
    properties ( Access = private, Constant)
        activate_loc = fullfile( "Scripts", "activate" )
    end
    
    methods ( Access = private )
        function opened = open_paraview( obj )
            setenv( "INTERFACE_FOLDER", obj.interface_folder );
            setenv( "INPUT_FOLDER", obj.input_folder );
            setenv( "NAME", obj.casting_name );
            log_file = sprintf("paraview_%s.log", datestr(datetime, "YYYYmmDD_HHMMSS"));
            cmd = ...
                obj.build_activate_conda_command() + " && " ...
                + obj.build_activate_environment_command() + " && " ...
                + "paraview --script=%s" ...
                + sprintf(">%s 2>&1" + newline, log_file);
            cmd = sprintf( cmd, obj.build_script_path() );
            fprintf( "Starting ParaView..." + newline );
            status = system( cmd, "-echo" );
            if status ~= 0
                error( "Unexpected error with ParaView." );
            end
            opened = ~status;
        end
        
        function installed = check_environment_installation( obj )
            fprintf( "Checking environment..." + newline );
            cmd = obj.build_activate_conda_command() + " && " ...
                + obj.build_activate_environment_command();
            cmd = sprintf( cmd, obj.environment_name );
            installed = ~system( cmd );
        end
        
        function install_environment( obj )
            fprintf( "Installing conda environment..." + newline );
            cmd = obj.build_activate_conda_command() + " && " ...
                + "conda env create --name %s --file ""%s"" --force";
            cmd = sprintf( cmd, obj.environment_name, obj.environment_file );
            status = system( cmd, "-echo" );
            if status ~= 0
                error( "Unexpected error installing environment." );
            end
        end
        
        function cmd = build_activate_conda_command( obj )
            cmd = obj.find_conda_activate();
            [ ~, name, ~ ] = fileparts( cmd );
            assert( strcmp( name, "activate" ) );
        end
        
        function cmd = build_activate_environment_command( obj )
            cmd = "conda activate %s";
            cmd = sprintf( cmd, obj.environment_name );
        end
        
        function path = find_conda_activate( obj )
            path = "";
            if obj.install_folder ~= ""
                path = obj.find_conda_activate_from_settings();
                if path == ""
                    fprintf( "Unable to find Anaconda at provided install folder:" + newline );
                    fprintf( "%s" + newline, obj.install_folder );
                end
            end
            if path == ""
                path = obj.find_conda_activate_from_fallback();
                if path == ""
                    fprintf( "Unable to find Anaconda at typical locations" + newline );
                end
            end
            if path == "" || ~isfile( path )
                error( "Unable to locate Anaconda on this machine." + newline );
            end
            path = strrep( path, "\", "/" );
        end
        
        function path = find_conda_activate_from_settings( obj )
            path = "";
            loc = fullfile( obj.install_folder, obj.activate_loc );
            if isfile( loc )
                path = loc;
            end
        end
        
        function path = find_conda_activate_from_fallback( obj )
            path = "";
            for loc = obj.get_locations()
                if isfile( loc )
                    path = loc;
                    break;
                end
            end
        end
        
        function path = build_script_path( obj )
            % have to normalize file separators and make absolute for ParaView
            path = GetFullPath( fullfile( obj.interface_folder, obj.script_file ), "/" );
        end
    end
    
    methods ( Access = private, Static )
        function locs = get_locations()
            envs = [ "LOCALAPPDATA" "PROGRAMDATA" ];
            anaconda = [ "anaconda3" "Anaconda3" ];
            locs = [];
            subfolder = Paraview.activate_loc;
            for env = envs
                env_path = string( getenv( env ) );
                for a = anaconda
                    locs = [ ...
                        locs ...
                        fullfile( env_path, "Continuum", a, subfolder ) ...
                        fullfile( env_path, a, subfolder ) ...
                        ]; %#ok<AGROW>
                end
            end
        end
    end
end