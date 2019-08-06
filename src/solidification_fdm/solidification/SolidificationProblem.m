classdef SolidificationProblem < ProblemInterface
    % @SolidificationProblem encapsulates the mathematical functions and
    % behavior relevant specifically to the PDE problem of solidification.
    %
    % Inputs:
    % - @mesh, a @MeshInterface representing the problem geometry.
    % - @pp, a @PhysicalProperties suitable for solidification problems.
    % - @primary_melt_id, the id associated with the primary melt in the @mesh.
    % - @u_init, a real, finite double vector with length equal to the number of
    % mesh elements. Represents the initial temperature field.
    
    properties ( SetAccess = private )
        u(:,1) double {mustBeReal,mustBeFinite}
        u_prev(:,1) double {mustBeReal,mustBeFinite}
        quality(1,1) double {mustBeReal,mustBeFinite}
    end
    
    properties ( SetAccess = private, Dependent )
        stop_temperature(1,1) double {mustBeReal,mustBeFinite}
    end
    
    methods
        function obj = SolidificationProblem( mesh, pp, primary_melt_id, u_init )
            assert( isa( mesh, 'MeshInterface' ) );
            
            assert( isa( u_init, 'double' ) );
            assert( isvector( u_init ) );
            assert( isreal( u_init ) );
            assert( all( isfinite( u_init ), 'all' ) );
            assert( numel( u_init ) == mesh.count );
            
            obj.u = u_init;
            obj.mesh = mesh;
            obj.solver = LinearSystemSolver();
            obj.pp = pp;
            obj.primary_melt_id = primary_melt_id;
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
            value = obj.pp.get_liquidus_temperature( obj.primary_melt_id );
        end
    end
    
    properties ( Access = private )
        A function_handle
        b function_handle
        u0(:,1) double {mustBeReal,mustBeFinite}
        mesh % MeshInterface
        solver LinearSystemSolver
        pp PhysicalProperties
        primary_melt_id(1,1) uint32 {mustBeNonnegative}
    end
    
    methods ( Access = private )
        function quality = compute_quality( obj, u )
            max_q_curr = max( obj.pp.lookup_values( obj.primary_melt_id, 'q', u ) );
            max_q_prev = max( obj.pp.lookup_values( obj.primary_melt_id, 'q', obj.u_prev ) );
            q_diff = max_q_prev - max_q_curr;
            latent_heat_fraction = obj.pp.get_min_latent_heat();
            quality = q_diff ./ latent_heat_fraction;
        end
    end
    
end

