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
        initial_time_step(1,1) double {mustBeReal,mustBeFinite,mustBePositive}
        stop_temperature(1,1) double {mustBeReal,mustBeFinite}
        primary_melt(:,1) logical
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
            obj.max_q_prev = max( obj.pp.lookup( obj.primary_melt_id, QProperty.name, obj.u_prev ) );
        end
        
        function solve( obj, dt )
            obj.u = obj.solver.solve( obj.A( dt ), obj.b( dt ), obj.u0 );
            obj.quality = obj.compute_quality( obj.u );
        end
        
        function finished = is_finished( obj )
            t = obj.stop_temperature();
            finished = all( double( obj.u <= t ), 'all' );
        end
        
        function value = get.initial_time_step( obj )
            % based on p421 of Ozisik _Heat Conduction_ 2e, originally from
            % Gupta and Kumar ref 79
            % Int J Heat Mass Transfer, 24, 251-259, 1981
            % see if there are improvements since?
            dx = max( obj.mesh.distances, [], 'all' );
            
            melt_id = obj.primary_melt_id;
            rho = obj.pp.reduce( melt_id, RhoProperty.name, @max );
            Tm = obj.pp.get_feeding_effectivity_temperature_c( melt_id );
            Tinf = obj.pp.ambient_temperature_c;
            
            L = obj.pp.get_latent_heat_j_per_kg( melt_id );
            S = obj.pp.get_sensible_heat_j_per_kg( melt_id );
            L = max( L, S ); % if latent heat very small, use sensible heat over freezing range instead
            
            h = -inf;
            ids = obj.pp.material_ids;
            for i = 1 : obj.pp.material_id_count
                id = ids( i );
                if id == melt_id; continue; end
                h = max( h, obj.pp.reduce_convection( melt_id, id, @max ) );
            end
            k = obj.pp.reduce( melt_id, KProperty.name, @min );
            H = h / k;
            
            numerator = rho * L * dx ^ 2 * ( 1 + H );
            denominator = h * ( Tm - Tinf );
            value = numerator / denominator;
            
            assert( value > 0 );
        end
        
        function value = get.stop_temperature( obj )
            value = obj.pp.get_liquidus_temperature_c( obj.primary_melt_id );
        end
        
        function value = get.primary_melt( obj )
            value = obj.mesh.map( @(x)x==obj.primary_melt_id );
        end
    end
    
    properties ( Access = private )
        A function_handle
        b function_handle
        u0(:,1) double {mustBeReal,mustBeFinite}
        mesh % MeshInterface
        solver LinearSystemSolver
        pp PhysicalProperties
        primary_melt_id(1,1) uint32
        max_q_prev(1,1) double {mustBeReal,mustBeFinite}
    end
    
    methods ( Access = private )
        function quality = compute_quality( obj, u )
            max_q_curr = max( obj.pp.lookup( obj.primary_melt_id, QProperty.name, u ) );
            q_diff = obj.max_q_prev - max_q_curr;
            latent_heat = obj.pp.get_latent_heat_j_per_kg( obj.primary_melt_id );
            quality = q_diff ./ latent_heat;
        end
    end
    
end

