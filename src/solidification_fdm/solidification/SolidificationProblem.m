classdef SolidificationProblem < ProblemInterface
    
    properties
        quality_ratio(1,1) double {mustBeReal,mustBeFinite,mustBeNonnegative} = 1.0
    end
    
    properties ( SetAccess = private )
        u(:,1) double
        u_prev(:,1) double
        quality(1,1) double
    end
    
    methods ( Access = public )
        function obj = SolidificationProblem( mesh, pp, cavity_id, u_init )
            obj.u = u_init;
            obj.mesh = mesh;
            obj.solver = LinearSystemSolver();
            obj.pp = pp;
            obj.cavity_id = cavity_id;
        end
        
        function prepare_system( obj )
            sk = SolidificationKernel( obj.pp, obj.mesh, obj.u );
            [ obj.A, obj.b, obj.u0 ] = sk.create_system();
            obj.u_prev = obj.u;
        end
        
        function solve( obj, dt )
            obj.u = obj.solver.solve( obj.A( dt ), obj.b( dt ), obj.u0 );
            obj.quality = obj.compute_quality( obj.u );
        end
    end
    
    properties ( Access = private )
        A function_handle
        b function_handle
        u0(:,1) double
        mesh
        solver LinearSystemSolver
        pp
        cavity_id(1,1) uint32 {mustBeNonnegative}
    end
    
    methods ( Access = private )
        function quality = compute_quality( obj, u )
            max_q_curr = max( obj.pp.lookup_values( obj.cavity_id, 'q', u ) );
            max_q_prev = max( obj.pp.lookup_values( obj.cavity_id, 'q', obj.u_prev ) );
            q_diff = max_q_prev - max_q_curr;
            latent_heat_fraction = obj.quality_ratio .* obj.pp.get_min_latent_heat();
            quality = q_diff ./ latent_heat_fraction;
        end
    end
    
end

