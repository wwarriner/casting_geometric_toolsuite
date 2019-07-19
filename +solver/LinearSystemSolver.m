classdef (Sealed) LinearSystemSolver < handle
    
    properties ( GetAccess = public, SetAccess = private )
        iteration_count(1,1) uint64 {mustBeNonnegative} = 0
        time(1,1) double {mustBeReal,mustBeFinite,mustBeNonnegative} = 0.0
    end
    
    properties ( Access = public )
        tolerance(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1e-4
        maximum_iteration_count(1,1) uint64 {mustBePositive} = 100
    end
    
    methods ( Access = public )
        
        function x = solve( obj, A, b, x0 )
            if nargin < 4
                x0 = [];
            end
            
            assert( ismatrix( A ) )
            
            assert( isvector( b ) )
            assert( length( b ) == size( A, 1 ) );
            
            if ~isempty( x0 )
                assert( isvector( x0 ) )
                assert( length( x0 ) == size( A, 1 ) );
            end
            
            obj.reset();
            
            tic;
            x = obj.solve_impl( A, b, x0 );
            obj.time = toc;
        end
        
    end
    
    
    methods ( Access = private )
        
        function reset( obj )
            obj.iteration_count = 0;
            obj.time = 0.0;
        end
        
        function x = solve_impl( obj, A, b, x0 )
            opts.michol = 'on';
            preconditioner = ichol( A, opts );
            [ x, ~, ~, obj.iteration_count, ~ ] = pcg( ...
                A, ...
                b, ...
                obj.tolerance, ...
                obj.maximum_iteration_count, ...
                preconditioner, ...
                preconditioner.', ...
                x0 ... % empty case handle internally
                );
            
        end
        
    end
    
end

