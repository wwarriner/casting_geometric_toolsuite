classdef (Sealed) ProcessManager < Cancelable & Notifier & Printer & handle
    
    properties
        user_needs(:,1) string = []
        overwrite_output(1,1) logical = false
    end
    
    methods ( Access = public )
        function obj = ProcessManager( settings, results )
            if nargin < 2
                results = Results( settings );
            end
            
            settings.manager.apply( obj );
            assert( ~isempty( obj.user_needs ) );
            
            obj.settings = settings;
            obj.results = results;
        end
        
        function output_files = prepare_output_files( obj )
            input_file = obj.settings.processes.Casting.input_file;
            [ input_folder, name, ~ ] = fileparts( input_file );
            output_folder = obj.settings.manager.output_folder;
            assert( ...
                ~strcmpi( input_folder, output_folder ) || ...
                ( isempty( input_folder ) && isempty( output_folder ) ) ...
                );
            write_folder = fullfile( output_folder, name );
            output_files = OutputFiles( ...
                write_folder, name, obj.overwrite_output ...
                );
        end
        
        function run( obj )
            obj.user_need_keys = obj.construct_user_need_keys();
            obj.iteration_limit = numel( obj.user_need_keys );
            obj.iteration = 1;
            obj.run_cancelable_loop();
        end
        
        function write_all( obj )
            if isempty( obj.output_files )
                obj.output_files = obj.prepare_output_files();
            end
            obj.write_data();
            obj.write_summary();
        end
        
        function write_data( obj )
            if isempty( obj.output_files )
                obj.output_files = obj.prepare_output_files();
            end
            obj.write_process_keys( obj.user_need_keys );
        end
        
        function write_summary( obj )
            if isempty( obj.output_files )
                obj.output_files = obj.prepare_output_files();
            end
            obj.printf( 'Writing summary...\n' );
            summary = obj.compose_summary();
            obj.output_files.write_table( "summary", summary );
        end
        
        function summary = compose_summary( obj )
            summary = obj.results.compose_summary( obj.user_need_keys );
        end
        
        function v = get( obj, process_key )
            v = obj.retrieve_process( process_key );
        end
    end
    
    properties ( Access = private )
        settings Settings
        results Results
        user_need_keys(:,1) ProcessKey
        output_files OutputFiles
        iteration_limit(1,1) uint32 {mustBePositive} = 1
        iteration(1,1) uint32
        process_names(:,1) string
    end
    
    methods ( Access = protected )
        function keep = keep_iterating( obj )
            keep = obj.iteration <= obj.iteration_limit;
        end
        
        function do_next_iteration( obj )
            process_key = obj.user_need_keys( obj.iteration );
            obj.retrieve_process( process_key );
            obj.iteration = obj.iteration + 1;
        end
    end
    
    methods ( Access = private )
        function keys = construct_user_need_keys( obj )
            count = numel( obj.user_needs );
            keys = ProcessKey.empty( count, 0 );
            for i = 1 : count
                need = obj.user_needs( i );
                keys( i ) = ProcessKey( need );
            end
        end
        
        function process = retrieve_process( obj, process_key )
            if ~obj.results.exists( process_key )
                process = obj.build_process( process_key );
                process.run();
                obj.results.add( process_key, process );
            else
                process = obj.results.get( process_key );
            end
        end
        
        function process = build_process( obj, process_key )
            process = process_key.create_instance( obj.results, obj.settings );
            process.attach_observer( obj.get_observer() );
        end
        
        function write_process_keys( obj, process_keys )
            for i = 1 : numel( process_keys )
                obj.write_result( process_keys( i ) );
            end
        end
        
        function write_result( obj, process_key )
            assert( ~isempty( obj.output_files ) );
            
            obj.printf( 'Writing %s...\n', process_key.name );
            result = obj.results.get( process_key );
            result.write( obj.output_files );
        end
    end
    
    methods ( Access = private, Static )
        % DO NOT REMOVE! NECESSARY FOR DEPLOYMENT
        function DUMMY_DO_NOT_CALL()
            process_implementation_includer();
        end
    end
    
end

