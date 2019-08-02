classdef SolidificationProblem < ProblemInterface
    
    properties
        quality_ratio(1,1) double {mustBeReal,mustBeFinite,mustBeNonnegative} = 1.0
    end
    
    properties ( SetAccess = private )
        u
        u_prev
        quality(1,1) double {mustBeReal,mustBeFinite}
    end
    
    properties ( SetAccess = private, Dependent )
        stop_temperature(1,1) double {mustBeReal,mustBeFinite}
    end
    
    methods
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
        
        function finished = is_finished( obj )
            stop_temperature = obj.stop_temperature();
            finished = all( double( obj.u <= stop_temperature ), 'all' );
        end
        
        function value = get.stop_temperature( obj )
            value = obj.pp.get_liquidus_temperature( obj.cavity_id );
        end
    end
    
    properties ( Access = private )
        A function_handle
        b function_handle
        u0
        mesh
        solver LinearSystemSolver
        pp PhysicalProperties
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

