classdef (Abstract) ProblemInterface < handle
    % @ProblemInterface is an interface all problems must extend to
    % be usable by this framework. The intent of the interface is to
    % standardize pde problem descriptions. Derived classes should hold
    % information and methods which facilitate computations pertaining to
    % the specific pde problem of interest to the user. It is recommended
    % that any problem kernels be stored in this class, and their
    % @create_system methods be called when @prepare_system is called.
    %
    % NOTE: Currently this interface is intentionally left vague.
    % Producing a generalized implementation of its intent will be quite
    % challenging. Methods will be explored, but this is likely beyond the
    % scope of any current research problems. Perhaps this will be updated
    % as we learn more from future work.
    %
    % Informally the workflow for a concrete @ProblemInterface is to store
    % a collection of kernels that represent transformations between
    % relevant problem fields and linear systems representing mesh
    % connectivity. The problem should be passed to a concrete
    % @IteratorBase to facilitate computation. When @prepare_system is
    % called by the iterator, the @create_system method of the kernels
    % should be called to produce function_handles which take time steps
    % and produce the actual system matrix and vector. Then when the
    % iterator produces a time step, it calls the @solve method, at which
    % point the problem uses the time step to generate the actual system of
    % equations from the previous preparation. Finally, the problem uses a 
    % concrete @SolverInterface to solve the systems to obtain the relevant
    % updated fields.
    
    methods ( Abstract )
        % @prepare_system provides a hook for preparing the system of
        % equations using stored kernels.
        prepare_system( obj );
        
        % @solve provides a hook for computing the relevant
        % fields from any stored kernels using relevant solvers.
        solve( obj, dt );
    end
    
end

