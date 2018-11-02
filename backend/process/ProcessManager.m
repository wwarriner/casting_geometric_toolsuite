classdef (Sealed) ProcessManager < Cancelable & Notifier & handle
    
    % TODO: figure out a way to "unwind" the dependencies to conserve memory
    % That is, when a process object is complete, perform all necessary outputs
    % with it, and if it has no more dependencies, then clear it from memory
    % EASY MODE: only clear sinks in the dependency digraph
    % HARD MODE: at the end of each loop, check all process objects to see if
    % they are a sink, may require storing a live digraph of visited nodes
    
    properties ( GetAccess = public, SetAccess = private )
        %% inputs
        user_needs
        parting_dimensions
        gravity_directions
        process_dependencies
        process_objects
        options
        
        %% outputs
        results
        
    end
    
    
    methods ( Access = public )
        
        function obj = ProcessManager( process_dependencies, options )
            
            obj.process_dependencies = process_dependencies;
            obj.options = options;
            obj.results = Results();
            
            if isprop( options, 'user_needs' )
                obj.set_user_needs( options.user_needs );
            end
            
            if isprop( options, 'parting_dimensions' )
                obj.set_parting_dimensions( options.parting_dimensions );
            else
                obj.set_parting_dimensions( 3 );
            end
            
            if isprop( options, 'gravity_directions' )
                obj.set_gravity_directions( options.gravity_directions );
            else
                obj.set_gravity_directions( { 'down' } );
            end
            
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
            
            
            % build processes
            [ base_process_names, class_names ] = ...
                obj.process_dependencies.get_process_order( obj.user_needs );
            count = numel( base_process_names );
            obj.process_objects = {};
            obj.process_names = {};
            for i = 1 : count
                obj.build_process_class_objects( ...
                    class_names{ i }, ...
                    base_process_names{ i } ...
                    );
            end
            
            % add processes to results object
            count = numel( obj.process_objects );
            for i = 1 : count
                
                obj.results.add( obj.process_names{ i }, obj.process_objects{ i } );
                
            end
            
            % set up and run loop
            obj.iteration_limit = numel( obj.process_names );
            obj.iteration = 1;
            obj.cancelable_loop();
            
        end
        
        
        function write_all( obj )
            
            keyset = obj.results.get_keys();
            obj.write( keyset );
            
        end
        
        
        function write( obj, keys )
            
            obj.prepare_writer();
            if ~iscell( keys )
                keys = { keys };
            end
            for i = 1 : numel( keys )
                
                obj.write_result( keys{ i }, obj.writer );
                
            end
            
        end
        
        
        function summary = generate_summary( obj, row_name )
            
            summary = table;
            
            keyset = obj.results.get_keys();
            for i = 1 : numel( keyset )
                
                key = keyset{ i };
                result = obj.results.get( key );
                summary = merge_tables( summary, result.to_summary(), key );
                
            end
            summary.Properties.RowNames = { row_name };
            
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
            
            process_name = obj.process_names{ obj.iteration };
            process_object = obj.process_objects{ obj.iteration };
            process_object.run();
            obj.results.add( process_name, process_object );
            obj.iteration = obj.iteration + 1;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        writer
        
    end
    
    
    methods ( Access = private )
        
        function prepare_writer( obj )
            
            assert( obj.results.exists( Component.NAME ) );
            assert( obj.results.exists( Mesh.NAME ) );
            name_of_component = obj.results.get( Component.NAME ).name;
            obj.writer = CommonWriter( ...
                obj.options.output_path, ...
                name_of_component, ...
                obj.results.get( Mesh.NAME ) ...
                );
            prepare_dir( obj.options.output_path );
            
        end
        
        
        function write_result( obj, key, writer )
            
            if obj.has_observer()
                obj.notify_observer( 'Writing :%s', key );
            end
            obj.results.get( key ).write( key, writer );
            
        end
        
        
        function build_process_class_objects( ...
                obj, ...
                class_name, ...
                base_process_name ...
                )


            pd = obj.get_parting_dimensions( class_name );
            gd = obj.get_gravity_directions( class_name );
            while ~pd.is_done()
                while ~gd.is_done()
                    
                    po = obj.build_base_object( class_name, pd, gd );
                    obj.process_objects{ end + 1 } = po;
                    name = obj.generate_process_name( base_process_name, pd, gd );
                    obj.process_names{ end + 1 } = name;
                    gd.move_to_next();
                    
                end
                gd.reset();
                pd.move_to_next();
            end
            
        end
        
        
        function dimensions = get_parting_dimensions( obj, class_name )
            
            if eval( [ class_name '.is_orientation_dependent()' ] )
                dimensions = obj.parting_dimensions;
            else
                dimensions = -1;
            end
            dimensions = PartingDirection( dimensions );
            
        end
        
        
        function directions = get_gravity_directions( obj, class_name )
            
            if eval( [ class_name '.has_gravity_direction()' ] )
                directions = obj.gravity_directions;
            else
                directions = { -1 };
            end
            directions = GravityDirection( directions );
            
        end
        
        
        function base_object = build_base_object( ...
                obj, ...
                class_name, ...
                parting_dimension, ...
                gravity_direction ...
                )
            
            base_object = feval( class_name, obj.results, obj.options );
            base_object.attach_observer( obj.get_observer() );
            if parting_dimension.is_orientation_dependent()
                base_object.set_parting_dimension( parting_dimension.get() );
            end
            if gravity_direction.is_gravity_dependent()
                base_object.set_gravity_direction( gravity_direction.get() );
            end
            
        end
        
        
        function process_name = generate_process_name( ...
                ~, ...
                base_process_name, ...
                parting_dimension, ...
                gravity_direction ...
                )
            
            process_name = base_process_name;
            process_name = parting_dimension.append_to_name( process_name );
            process_name = gravity_direction.append_to_name( process_name );
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        % DO NOT REMOVE! NECESSARY FOR DEPLOYMENT
        function DUMMY_DO_NOT_CALL()
            
            process_implementation_includer();
            
        end
        
    end
    
end

