classdef (Sealed) LinearSystemSolver < modeler.super.Solver
    
    methods ( Access = public )
        
        function obj = LinearSystemSolver()
            
            obj.tolerance = 1e-4;
            obj.maximum_iteration_count = 100;
            
        end
        
        
        function set_tolerance( obj, tolerance )
            
            assert( isscalar( tolerance ) );
            assert( isa( tolerance, 'double' ) );
            assert( 0 < tolerance );
            
            obj.tolerance = tolerance;
            
        end
        
        
        function set_maximum_iterations( obj, count )
            
            assert( isscalar( count ) );
            assert( isa( count, 'double' ) );
            assert( 0 < count );
            
            obj.maximum_iteration_count = count;
            
        end
        
        
        function x = solve( obj, A, b, x0 )
            
            if nargin < 4
                x0 = [];
            end
            x = obj.solve_impl( A, b, x0 );
            
        end
        
        
        function count = get_iteration_count( obj )
            
            count = obj.iteration_count;
            
        end
        
        
        function time = get_time( obj )
            
            time = obj.time;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        tolerance
        maximum_iteration_count
        
        initial_guess
        iteration_count
        time
        
    end
    
    
    methods ( Access = private )
        
        function x = solve_impl( obj, A, b, x0 )
            
            tic;
            
            preconditioner = ichol( A, struct( 'michol', 'on' ) );
            if ~isempty( x0 )
                [ x, ~, ~, obj.iteration_count, ~ ] = pcg( ...
                    A, ...
                    b, ...
                    obj.tolerance, ...
                    obj.maximum_iteration_count, ...
                    preconditioner, ...
                    preconditioner.', ...
                    x0( : ) ...
                    );
            else
                [ x, ~, ~, obj.iteration_count, ~ ] = pcg( ...
                    A, ...
                    b, ...
                    obj.tolerance, ...
                    obj.maximum_iteration_count, ...
                    preconditioner, ...
                    preconditioner.' ...
                    );
            end
            
            obj.time = toc;
            
        end
        
    end
    
end

