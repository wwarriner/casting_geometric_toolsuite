classdef OrientationOptimizer < handle
    
    properties ( GetAccess = public, SetAccess = private )
        
        component
        feeders
        element_count
        
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
        
        % objective metric is function of the form
        % [objective]@(fn,angles)
        % where fn is a function of the form [c,m,f]@(angles)
        % where c, m, f are rotated component, mesh, feeders
        function run( ...
                obj, ...
                population_count, ...
                generation_count, ...
                objective_metric ...
                )
            
            cleanup_tasks = onCleanup( @Print.turn_print_on );
            Print.turn_print_off();
            obj.run_setup( ...
                population_count, ...
                generation_count, ...
                objective_metric ...
                );
            obj.run_impl();
            
        end
        
        
        function [ c, m, f ] = rotate( obj, angles )
            
            r = rotator( angles );
            c = obj.component.rotate( r );
            if nargout > 1
                m = Mesh();
                m.legacy_run( c, obj.element_count );
            end
            if nargout > 2
                f = obj.feeders.rotate( r, m );
            end
            
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
        
        
        function [ fh, axh, ph ] = plot_minima( obj )
            
            fh = figure( 'color', 'w' );
            axh = axes( fh );
            hold( axh, 'on' );
            axis( axh, 'equal' );
            ph = plot( obj.minima( :, 1 ), obj.minima( :, 2 ), 'k.' );
            axh.XLim = [ -pi pi ];
            axh.XTick = [ -pi, -pi/2, 0, pi/2, pi ];
            axh.XTickLabel = { '-\pi', '-\pi/2', '0', '\pi/2', '\pi' };
            axh.YLim = [ -pi/2 pi/2 ];
            axh.YTick = [ -pi/2, 0, pi/2 ];
            axh.YTickLabel = { '-\pi/2', '0', '\pi/2' };
            
        end
        
        
        function [ fh, axh, phs ] = draw_rotated_geometry( obj, angles )
            
            [ c, ~, f ] = obj.rotate( angles );
            fh = figure( 'color', 'w' );
            axh = axes( fh );
            hold( axh, 'on' );
            axis( axh, 'equal' );
            axis( axh, 'vis3d' );
            bg = [ ...
                [ 0 0 0 ]; ...
                [ 0.5 0.5 0.5 ]; ...
                [ 1 1 1 ] ...
                ];
            colors = distinguishable_colors( f.count, bg );
            phs = cell( f.count + 1, 1 );
            for i = 1 : f.count
                
                phs{ i } = patch( f.feeders( i ).fv, 'facecolor', colors( i, : ), 'facealpha', 0.5 );
                
            end
            phs{ end } = patch( c.fv, 'facecolor', [ 0.5 0.5 0.5 ], 'facealpha', 0.5 );
            
        end
        
    end
    
    
    methods ( Access = protected, Abstract )
        
        run_impl( obj );
        solver = get_solver( ~ );
        solver_optimset_fn = get_solver_optimset_fn( ~ );
        
    end
    
    
    methods ( Access = protected )
        
        function obj = OrientationOptimizer( ...
                component, ...
                feeders, ...
                element_count ...
                )
            
            obj.component = component;
            obj.feeders = feeders;
            obj.element_count = element_count;
            
        end
        
        
        function run_setup( ...
                obj, ...
                objective_metric, ...
                population_count, ...
                generation_count ...
                )
            
            run_metric = @(angles)objective_metric( ...
                @obj.rotate, ...
                angles ...
                );
            obj.problem = obj.generate_problem( run_metric );
            obj.problem.options = obj.generate_options( ...
                population_count, ...
                generation_count ...
                );
            
            obj.print_new_gen( obj.problem.options );
            
        end
        
    end
    
    
    methods ( Access = private )
        
        function problem = generate_problem( ...
                obj, ...
                objective_metric ...
                )
            
            problem = struct();
            problem.solver = obj.get_solver();
            problem.fitnessfcn = objective_metric;
            problem.nvars = 2;
            problem.lb = [ -pi(); -pi()./2 ];
            problem.ub = [ pi(); pi()./2 ];
            
        end
        
        
        function options = generate_options( ...
                obj, ...
                population_count, ...
                generation_count ...
                )
            
            options = gaoptimset( obj.get_solver_optimset_fn() );
            options.MutationFcn = @mutationadaptfeasible;
            options.PopulationSize = population_count;
            options.Generations = generation_count;
            options.OutputFcns = { ...
                @obj.capture_new_gen, ...
                @obj.print_new_gen ...
                };
            options.UseParallel = true;
            
        end
        
        
        function [ state, options, optchanged ] = capture_new_gen( ...
                obj, ...
                options, ...
                state, ...
                ~ ...
                )
            
            obj.history = [ obj.history; state ];
            optchanged = false;
            
        end
        
        
        function [ state, options, optchanged ] = print_new_gen( ...
                ~, ...
                options, ...
                state, ...
                ~ ...
                )
            
            if nargin < 3
                generation_count = 0;
            else
                generation_count = state.Generation + 1;
            end
            
            fprintf( 'Generation %d progress:\n', generation_count );
            fprintf( '%s\n\n', repmat( '.', 1, options.PopulationSize ) );
            optchanged = false;
            
        end
        
    end
    
end

