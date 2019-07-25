classdef (Sealed) ProcessManager < Cancelable & Notifier & handle
    
    properties ( GetAccess = public, SetAccess = private )
        
        % inputs
        user_needs
        parting_dimensions
        gravity_directions
        options
        
        % outputs
        process_keys
        results
        
    end
    
    
    methods ( Access = public )
        
        function obj = ProcessManager( options, results )
            
            if nargin < 2
                results = Results( options );
            end
            
            obj.options = options;
            obj.results = results;
            
            input_folder = fileparts( obj.options.get( 'manager.stl_file' ) );
            output_folder = obj.options.get( 'manager.output_folder' );
            assert( ...
                ~strcmpi( input_folder, output_folder ) || ...
                ( isempty( input_folder ) && isempty( output_folder ) ) ...
                );
            
            obj.user_needs = obj.options.get( 'manager.user_needs' );
            obj.parting_dimensions = obj.options.get( ...
                'manager.parting_dimensions', ...
                Process.DEFAULT_PARTING_DIMENSION ...
                );
            obj.gravity_directions = obj.options.get( ...
                'manager.gravity_directions', ...
                Process.DEFAULT_GRAVITY_DIRECTION ...
                );
            
        end
        
        
        function set_user_needs( obj, user_needs )
            
            obj.user_needs = user_needs;
            
        end
        
        
        function set_parting_dimensions( obj, parting_dimensions )
            
            obj.parting_dimensions = parting_dimensions;
            
        end
        
        
        function set_gravity_directions( obj, gravity_directions )
            
            obj.gravity_directions = gravity_directions;
            
        end
        
        
        function run( obj )
            
            assert( ~isempty( obj.user_needs ) );
            assert( ~isempty( obj.parting_dimensions ) );
            assert( ~isempty( obj.gravity_directions ) );
            
            obj.process_keys = obj.construct_keys( obj.user_needs );
            obj.iteration_limit = numel( obj.process_keys );
            obj.iteration = 1;
            obj.run_cancelable_loop();
            
        end
        
        
        function write( obj )
            
            obj.write_process_keys( obj.process_keys );
            
        end
        
        
        function summary = generate_summary( obj )
            
            summary = table;
            r = obj.results.get_all();
            for i = 1 : numel( r )
                
                result = r{ i };
                summary = [ ...
                    summary ...
                    result.to_summary( result.NAME ) ...
                    ]; %#ok<AGROW>
                
            end
            summary.Properties.RowNames = { obj.get_name() };
            
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

                process_name = user_needs{ i };
                pd = obj.get_parting_dimensions( process_name );
                gd = obj.get_gravity_directions( process_name );
                while ~pd.is_done()
                    while ~gd.is_done()

                        pk = ProcessKey( ...
                            process_name, ...
                            pd.get(), ...
                            gd.get() ...
                        );
                        keys{ end + 1 } = pk; %#ok<AGROW>
                        gd.move_to_next();

                    end
                    gd.reset();
                    pd.move_to_next();
                end
                
            end
            
        end
        
        
        function dimensions = get_parting_dimensions( obj, class_name )
            
            if ProcessKey.use_parting_dimensions( class_name )
                dimensions = obj.parting_dimensions;
            else
                dimensions = [];
            end
            dimensions = PartingDirection( dimensions );
            
        end
        
        
        function directions = get_gravity_directions( obj, class_name )
            
            if ProcessKey.use_gravity_directions( class_name )
                directions = obj.gravity_directions;
            else
                directions = [];
            end
            directions = GravityDirection( directions );
            
        end
        
        
        function instance = build_process( obj, process_key )
            
            instance = process_key.create_instance( obj.results, obj.options );
            instance.attach_observer( obj.get_observer() );
            
        end
        
        
        function write_process_keys( obj, process_keys )
            
            writer = obj.prepare_writer();
            for i = 1 : numel( process_keys )
                
                obj.write_result( process_keys{ i }, writer );
                
            end
            
        end
        
        
        function write_result( obj, process_key, writer )
            
            if obj.has_observer()
                obj.notify_observer( 'Writing :%s', process_key );
            end
            result = obj.results.get( process_key );
            result.write( process_key.to_string(), writer );
            
        end
        
        
        function writer = prepare_writer( obj )
            
            mesh_key = ProcessKey( Mesh.NAME );
            assert( obj.results.exists( mesh_key ) );
            
            name_of_component = obj.get_name();
            output_path = obj.options.get( 'manager.output_folder' );
            writer = CommonWriter( ...
                fullfile( output_path, name_of_component ), ...
                name_of_component, ...
                obj.results.get( mesh_key ) ...
                );
            writer.prepare_output_path();
            
        end
        
        
        function name = get_name( obj )
            
            component_key = ProcessKey( Component.NAME );
            assert( obj.results.exists( component_key ) );
            name = obj.results.get( component_key ).name;
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        % DO NOT REMOVE! NECESSARY FOR DEPLOYMENT
        function DUMMY_DO_NOT_CALL()
            
            process_implementation_includer();
            
        end
        
    end
    
end

