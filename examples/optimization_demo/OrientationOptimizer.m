classdef OrientationOptimizer < handle
    
    properties ( GetAccess = public, SetAccess = private )
        
        base_case
        optimization_routine
        
        problem
        history
        
    end
    
    
    properties ( GetAccess = public, SetAccess = protected )
        
        minima
        function_values
        exitflag
        output
        
    end
    
    
    methods ( Access = public )
        
        function obj = OrientationOptimizer( base_case, optimization_routine )
            
            obj.base_case = base_case;
            obj.optimization_routine = optimization_routine;
            
        end
        
        % objective metric is function of the form
        % [objective]@(fn,angles)
        % where fn is a function of the form [c,m,f]@(angles)
        % where c, m, f are rotated component, mesh, feeders
        function run( obj, options )
            
            cleanup_tasks = onCleanup( @Print.turn_print_on );
            Print.turn_print_off();
            
            options.OutputFcns = [ ...
                options.OutputFcns, ...
                @obj.capture_new_gen, ...
                @obj.print_new_gen ...
                ];
            function objectives = obj_fn( angles )
                
                objectives = obj.base_case.determine_objectives( angles );
                obj.count = obj.count + 1;
                fprintf( '|' );
                
            end
            [ obj.minima, obj.function_values, obj.exitflag, obj.output ] ...
                = obj.optimization_routine( ...
                @obj_fn, ...
                obj.base_case.get_decision_variable_count(), ...
                [], ...
                [], ...
                [], ...
                [], ...
                obj.base_case.get_decision_variable_lower_bounds(), ...
                obj.base_case.get_decision_variable_upper_bounds(), ...
                [], ...
                options ...
                );
            
        end
        
        
        function [ full_population, full_scores ] = get_all_trials( obj )
            
            full_population = [ obj.history.Population ].';
            row_count = obj.problem.nvars;
            [ full_population, unique_inds ] = unique( reshape( full_population, row_count, [] ).', 'rows' );
            
            full_scores = [ obj.history.Score ].';
            score_count = size( obj.history( 1 ).Score, 1 ) .* ( obj.problem.options.Generations + 1 );
            row_count = numel( full_scores ) ./ score_count;
            full_scores = reshape( full_scores, row_count, [] ).';
            full_scores = full_scores( unique_inds, : );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        iteration_count
        
    end
    
    
    methods ( Access = private )
        
        function [ stop, options, optchanged ] = capture_new_gen( ...
                obj, ...
                optimization_values, ...
                options, ...
                flag ...
                )
            
            if ~strcmpi( flag, 'interrupt' )
                current_decisions = optimization_values.x( : ).';
                current_objectives = optimization_values.fval( : ).';
                obj.history = [ ...
                    obj.history; ...
                    current_decisions current_objectives ...
                    ];
            end
            
            stop = false;
            optchanged = false;
            
        end
        
        
        function [ stop, options, optchanged ] = print_new_gen( ...
                obj, ...
                optimization_values, ...
                options, ...
                flag ...
                )
            
            if ~strcmpi( flag, 'interrupt' )
                current_decisions = optimization_values.x( : ).';
                current_objectives = optimization_values.fval( : ).';
                obj.history = [ ...
                    obj.history; ...
                    current_decisions current_objectives ...
                    ];
            end
            
            if mod( obj.count, 50 ) == 0
                fprintf( 1, '\n' );
            end
            
            stop = false;
            optchanged = false;
            
        end
        
    end
    
end

