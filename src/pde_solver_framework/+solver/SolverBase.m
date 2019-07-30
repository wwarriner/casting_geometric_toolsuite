classdef (Abstract) SolverBase < handle
    % @SolverBase is a base class implementing common functionality for
    % linear algebra-based solves of systems of equations. The intent of
    % this class is to provide a standard way of solving systems of
    % equations. Most systems will probably be served well by the included
    % @LinearSystemSolver. If that is not well-suited to the problem at
    % hand, the user is free to implement a new solver by creating a new
    % concrete class and implementing the @solve_impl method.
    
    properties
        tolerance(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1e-4
        maximum_iteration_count(1,1) uint32 {mustBePositive} = 100
    end
    
    properties ( SetAccess = private )
        iteration_count(1,1) uint32 {mustBeNonnegative} = 0
        time(1,1) double {mustBeReal,mustBeFinite,mustBeNonnegative} = 0.0
    end
    
    methods
        % @solve solves for vector x in a system of equations represented
        % by matrix A, vector b, using initial guess vector x0.
        % Inputs:
        % - A is an m by n matrix of doubles
        % - b is a length m vector of doubles
        % - x0 is either a length n vector of doubles, or empty
        % Outputs:
        % - x is a length m vector of doubles
        function x = solve( obj, A, b, x0 )
            assert( isa( A, 'double' ) );
            assert( ismatrix( A ) );
            
            assert( isa( b, 'double' ) );
            assert( isvector( b ) );
            assert( length( b ) == size( A, 1 ) );
            
            if ~isempty( x0 )
                assert( isa( b, 'double' ) );
                assert( isvector( x0 ) );
                assert( length( x0 ) == size( A, 1 ) );
            end
            
            tic;
            [ x, obj.iteration_count ] = obj.solve_impl( A, b, x0 );
            obj.time = toc;
        end
    end
    
    methods ( Abstract, Access = protected )
        % @solve_impl must be implemented by the user in derived classes so
        % that @solve can be used.
        % Inputs:
        % - A is an m by n matrix of doubles
        % - b is a length m vector of doubles
        % - x0 is either a length n vector of doubles, or empty
        % Outputs:
        % - x is a length m vector of doubles
        % - iteration_count is a scalar double representing the number of
        % iterations of any internal solver mechanisms
        [ x, iteration_count ] = solve_impl( obj, A, b, x0 );
    end
    
end

