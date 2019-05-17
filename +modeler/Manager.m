classdef (Sealed) Manager < handle
    
    methods ( Access = public )
        
        function obj = Manager( ...
                fdm_mesh, ...
                physical_properties, ...
                solver, ...
                problem, ...
                iterator, ...
                results ...
                )
            
            assert( isa( solver, 'modeler.super.Solver' ) );
            assert( isa( problem, 'modeler.super.Problem' ) );
            assert( isa( iterator, 'modeler.super.Iterator' ) );
            
            obj.mesh = fdm_mesh;
            obj.physical_properties = physical_properties;
            obj.solver = solver;
            obj.problem = problem;
            obj.iterator = iterator;
            obj.results = results;
            
            obj.dashboard = [];
            
        end
        
        
        function turn_printing_on( obj, printer )
            
            obj.printing = true;
            obj.printer = printer;
            
        end
        
        
        function set_dashboard( obj, dashboard )
            
            obj.dashboard = dashboard;
            
        end
        
        
        function solve( obj )
            
            wallclock_timer = tic;
            while ~obj.problem.is_finished()
                
                obj.iterator.iterate();
                obj.update_results();
                obj.update_dashboard();
                
            end
            obj.wallclock_time = toc( wallclock_timer );
            
        end
        
        
        function keys = get_result_list( obj )
            
            keys = obj.results.keys();
            
        end
        
        
        function result = get_scalar_field( obj, key, nan_val )
            
            if nargin < 3
                nan_val = nan;
            end
            
            result = obj.results( key ).get_scalar_field();
            result( isnan( result ) ) = nan_val;
            
        end
        
        
        function display_computation_time_summary( obj )
            
            fh = figure();
            fh.Position = [ 50 50 300 800 ];
            axh = axes( fh );
            values = cell2mat( obj.computation_times.values() );
            values = values( : ).' ./ sum( values( : ) ) .* 100;
            nb = nan( size( values( : ).' ) );
            bb = [ values; nb ];
            bar( bb, 'stacked' );
            axh.XLim = [ 0.5 1.5 ];
            axh.YLim = [ 0 100 ];
            ytickformat( axh, '%g%%' );
            labels = obj.computation_times.keys();
            base_positions = cumsum( values );
            label_positions = base_positions - values ./ 2;
            for i = 1 : length( values )
                
                text( ...
                    axh.XTick( 1 ), label_positions( i ), ...
                    sprintf( '%s: %.2f%%', labels{ i }, values( i ) ), ...
                    'horizontalalignment', 'center', ...
                    'verticalalignment', 'middle' ...
                    );
                
            end
            
        end
        
        
        function print_summary( obj )
            
            obj.print( 'Iteration Count: %d\n', obj.iteration_count );
            obj.print( 'Solver Count: %d\n', obj.solver_count );
            obj.print( 'Approximate Computation Times: ' );
            obj.print( '%.2fs, ', obj.get_computation_times() );
            obj.print( '\n' );
            obj.print( 'Total Computation Time: %.2fs\n', obj.get_total_computation_time() );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        mesh
        physical_properties
        solver
        problem
        iterator
        results
        
        dashboard
        
        wallclock_time
        
    end
    
    
    methods ( Access = private )
        
        function update_results( obj )
            
            r = obj.results.values();
            for i = 1 : obj.results.Count()
                
                result = r{ i };
                result.update( ...
                    obj.mesh, ...
                    obj.physical_properties, ...
                    obj.iterator, ...
                    obj.problem ...
                    );
                
            end
            
        end
        
        
        function update_dashboard( obj )
            
            if ~isempty( obj.dashboard )
                obj.dashboard.update();
            end
            
        end
        
    end
    
end

