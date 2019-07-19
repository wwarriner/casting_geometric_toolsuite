classdef SolidificationMetaKernel < handle
    
    properties
        quality_ratio(1,1) double {mustBeReal,mustBeFinite,mustBeNonnegative} = 1.0
    end
    
    properties ( SetAccess = private )
        u(:,1) double
    end
    
    methods ( Access = public )
        
        function obj = SolidificationMetaKernel( kernel, solver, pp, cavity_id )
            [ obj.A, obj.b, obj.u0 ] = kernel.create_system();
            obj.solver = solver;
            obj.pp = pp;
            obj.cavity_id = cavity_id;
        end
        
        function quality = apply_time_step( obj, dt )
            obj.u = obj.solver.solve( obj.A( dt ), obj.b( dt ), obj.u0 );
            quality = obj.compute_quality( obj.u );
        end
        
    end
    
    
    properties ( Access = private )
        A(1,1) function_handle = @()[]
        b(1,1) function_handle = @()[]
        u0(:,1) double
        solver(1,1) solver.LinearSystemSolver
        pp
        cavity_id(1,1) uint64 {mustBeNonnegative}
    end
    
    
    methods ( Access = private )
        
        function quality = compute_quality( obj, u )
            max_q_curr = max( obj.pp.lookup_values( obj.cavity_id, 'q', u ) );
            max_q_prev = max( obj.pp.lookup_values( obj.cavity_id, 'q', obj.u0 ) );
            q_diff = max_q_prev - max_q_curr;
            latent_heat_fraction = obj.quality_ratio .* obj.pp.get_min_latent_heat();
            quality = q_diff ./ latent_heat_fraction;
        end
        
    end
    
end

