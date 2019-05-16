classdef (Sealed) FdmManager < handle
    
    methods ( Access = public )
        
        function obj = FdmManager( ...
                solver, ...
                problem, ...
                iterator, ...
                results ...
                )
            
            obj.solver = solver;
            obj.problem = problem;
            obj.iterator = iterator;
            obj.results = results;
            
            obj.computation_times = containers.Map();
            
        end
        
        
        function turn_printing_on( obj, printer )
            
            obj.printing = true;
            obj.printer = printer;
            
        end
        
        
        function set_live_plotting( obj, on )
            
            obj.live_plotting = on;
            
        end
        
        
        function turn_live_plotting_on( obj )
            
            obj.live_plotting = true;
            
        end
        
        
        % warning! memory intensive!
        function turn_full_data_storage_on( obj )
            
            obj.data_storage = true;
            
        end
        
        
        function solve( obj )
            
            while ~obj.problem.is_finished()
                
                obj.iterator.iterate();
                obj.update_results();
                
            end
            
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
        
        solver
        problem
        iterator
        results
        
        linear_system_iteration_count
        time_step_method_count
        time_steps
        computation_times
        
    end
    
    
    methods ( Access = private )
        
        function update_results( obj )
            
            % for each result, update it
            
        end
        
    end
    
end

