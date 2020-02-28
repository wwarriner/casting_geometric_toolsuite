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
            if ~obj.check_installed()
                fprintf( ...
                    "Unable to locate existing environment." + newline ...
                    + "If this is your first time using this software, this is expected." + newline ...
                    );
                obj.install_environment();
            end
            opened_ok = obj.open_paraview();
            if ~opened_ok
                fprintf( "Unable to open paraview, reinstalling environment." + newline );
                obj.install_environment();
                opened_ok = obj.open_paraview();
            end
            if ~opened_ok
                error( ...
                    "Unexpected error opening paraview after fresh install." + newline ...
                    + "Please contact the software creator for support." + newline ...
                    );
            end
        end
    end
    
    methods
        function set.casting_name( obj, value )
            obj.casting_name = value;
        end
    end
    
    properties ( Access = private )
        environment_file(1,1) string
        environment_name(1,1) string
        install_folder(1,1) string
        interface_folder(1,1) string
        script_file(1,1) string
    end
    
    methods ( Access = private )
        function opened = open_paraview( obj )
            setenv( "INTERFACE_FOLDER", obj.interface_folder );
            setenv( "INPUT_FOLDER", obj.input_folder );
            setenv( "NAME", obj.casting_name );
            cmd = ...
                obj.activate_conda() + " && " ...
                + obj.activate_environment() + " && " ...
                + "START /WAIT paraview --script=%s";
            cmd = sprintf( cmd, obj.build_script_path() );
            status = system( cmd, "-echo" );
            if status ~= 0
                error( "Unexpected error starting conda." );
            end
            opened = ~status;
        end
        
        function installed = check_installed( obj )
            cmd = obj.activate_conda() + " && " ...
                + obj.activate_environment();
            cmd = sprintf( cmd, obj.environment_name );
            installed = ~system( cmd );
        end
        
        function install_environment( obj )
            fprintf( "Installing environment..." + newline );
            cmd = obj.activate_conda() + " && " ...
                + "conda env create --name %s --file ""%s"" --force";
            cmd = sprintf( cmd, obj.environment_name, obj.environment_file );
            status = system( cmd, "-echo" );
            if status ~= 0
                error( "Unexpected error installing environment." );
            end
        end
        
        function cmd = activate_environment( obj )
            cmd = "conda activate %s";
            cmd = sprintf( cmd, obj.environment_name );
        end
        
        function cmd = activate_conda( obj )
            cmd = obj.find_conda_activate();
            [ ~, name, ~ ] = fileparts( cmd );
            assert( strcmp( name, "activate" ) );
        end
        
        function path = find_conda_activate( obj )
            path = obj.build_from_settings();
            if path == ""
                path = obj.build_from_fallback();
            end
            if path == "" || ~isfile( path )
                error( "Unable to locate Anaconda3." + newline );
            end
            path = strrep( path, "\", "/" );
        end
        
        function path = build_from_settings( obj )
            path = "";
            try
                path = obj.install_folder;
                activate_suffix = fullfile( "Scripts", "activate" );
                path = obj.build_conda_activate_path( path, activate_suffix );
            catch e
                fprintf( "Unable to read conda install folder from settings." + newline );
                return;
            end
        end
        
        function path = build_from_fallback( obj )
            fprintf( "Attempting to locate conda at typical install locations." + newline );
            
            path = "";
            try
                path = obj.build_from_env( "LOCALAPPDATA" );
            catch e
                % do nothing
            end
            if path == "" || ~isfile( path )
                try
                    path = obj.build_from_env( "PROGRAMDATA" );
                catch e
                    % do nothing
                end
            end
        end
        
        function path = build_from_env( obj, env )
            path = obj.build_conda_activate_path( ...
                string( getenv( env ) ), ...
                obj.build_full_suffix() ...
                );
        end
        
        function path = build_script_path( obj )
            % have to normalize file separators and make absolute for ParaView
            path = GetFullPath( fullfile( obj.interface_folder, obj.script_file ), "/" );
        end
    end
    
    methods ( Access = private, Static )
        function suffix = build_full_suffix()
            sub_suffix = Paraview.build_sub_suffix();
            suffix = fullfile( "Continuum", "anaconda3", sub_suffix );
        end
        
        function suffix = build_sub_suffix()
            suffix = fullfile( "Scripts", "activate" );
        end
        
        function path = build_conda_activate_path( folder, suffix )
            activate = fullfile( folder, suffix );
            path = "";
            if isfile( activate )
                path = activate;
            end
        end
    end
end