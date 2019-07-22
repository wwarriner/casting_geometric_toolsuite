classdef (Abstract) KernelInterface < handle
    % @KernelInterface is an interface all problem kernels must extend to
    % be usable by this framework. The intent of the interface is to
    % standardize solving pde problems. Derived classes should hold
    % information and methods which facilitate conversion of field data
    % into a system of equations solvable by matrix equation solvers.
    
    methods ( Abstract, Access = public )
        % @create_system creates a system of equations in the form A*x=b,
        % with initial guess x0.
        % Outputs:
        % - A is a function_handle whose input is a time step, and whose
        % output is an m by n matrix of doubles
        % - b is a function_handle whose input is a time step, and whose
        % outputs an m length vector of doubles
        % - x0 is an m length vector of doubles
        [ A, b, x0 ] = create_system( obj )
    end
    
end

