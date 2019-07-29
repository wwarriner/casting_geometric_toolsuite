classdef (Sealed) ProcessManager < Cancelable & Notifier & handle
        
    properties ( SetAccess = private )
        user_needs
        options
        process_keys
        results
    end
    
    methods ( Access = public )
        
        function obj = ProcessManager( options, results )
            if nargin < 2
                results = Results( options );
            end
            
            input_folder = fileparts( options.get( 'manager.stl_file' ) );
            output_folder = options.get( 'manager.output_folder' );
            assert( ...
                ~strcmpi( input_folder, output_folder ) || ...
                ( isempty( input_folder ) && isempty( output_folder ) ) ...
                );
            obj.user_needs = options.get( 'manager.user_needs' );
            obj.options = options;
            obj.results = results;
        end
        
        function run( obj )
            obj.process_keys = obj.construct_keys( obj.user_needs );
            obj.iteration_limit = numel( obj.process_keys );
            obj.iteration = 1;
            obj.run_cancelable_loop();
        end
        
        function write( obj )
            obj.write_process_keys( obj.process_keys );
        end
        
        function summary = generate_summary( obj )
            % TODO
        end
        
    end
    
    properties ( Access = protected )
        iteration_limit
        iteration
        process_names
    end
    
    methods ( Access = protected )
        function keep = keep_iterating( obj )
            keep = obj.iteration <= obj.iteration_limit;
        end
        
        function do_next_iteration( obj )
            process_key = obj.process_keys{ obj.iteration };
            if ~obj.results.exists( process_key )
                process = obj.build_process( process_key );
                process.run();
                obj.results.add( process_key, process );
            else
                % already run as a dependency
            end
            obj.iteration = obj.iteration + 1;
        end
    end
    
    methods ( Access = private )
        function keys = construct_keys( obj, user_needs )
            count = numel( user_needs );
            keys = {};
            for i = 1 : count
                pk = ProcessKey( user_needs{ i } );
                keys{ end + 1 } = pk; %#ok<AGROW>
            end
        end
        
        function instance = build_process( obj, process_key )
            instance = process_key.create_instance( obj.results, obj.options );
            instance.attach_observer( obj.get_observer() );
        end
        
        function write_process_keys( obj, process_keys )
            output_files = obj.prepare_output_files();
            for i = 1 : numel( process_keys )
                obj.write_result( process_keys{ i }, output_files );
            end
        end
        
        function write_result( obj, process_key, output_files )
            if obj.has_observer()
                obj.notify_observer( 'Writing :%s', process_key );
            end
            result = obj.results.get( process_key );
            result.write( output_files );
        end
        
        function output_files = prepare_output_files( obj )
            name = obj.get_name();
            output_folder = obj.options.get( 'manager.output_folder' );
            write_folder = fullfile( output_folder, name );
            output_files = OutputFiles( write_folder, name );
            output_files.prepare_output_path();
        end
        
        function name = get_name( obj )
            casting_key = ProcessKey( Casting.NAME );
            assert( obj.results.exists( casting_key ) );
            name = obj.results.get( casting_key ).name;
        end
    end
    
    methods ( Access = private, Static )
        % DO NOT REMOVE! NECESSARY FOR DEPLOYMENT
        function DUMMY_DO_NOT_CALL()
            process_implementation_includer();
        end
    end
    
end

