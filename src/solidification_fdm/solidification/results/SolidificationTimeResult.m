classdef SolidificationTimeResult < ResultInterface
    
    properties ( SetAccess = private )
        values
    end
    
    properties ( SetAccess = private, Dependent )
        modulus
    end
    
    methods
        function obj = SolidificationTimeResult( mesh, problem, iterator )
            assert( isa( mesh, 'MeshInterface' ) );
            
            assert( isa( iterator, 'IteratorBase' ) );
            
            obj.values = nan( mesh.count, 1 );
            obj.problem = problem;
            obj.mesh = mesh;
            obj.iterator = iterator;
        end
        
        function update( obj )
            % which
            is_melt = obj.problem.primary_melt;
            past_threshold = obj.problem.u <= obj.problem.stop_temperature;
            unrecorded = isnan( obj.values );
            needs_update = is_melt & past_threshold & unrecorded;
            
            % compute
            u_prev = obj.problem.u_prev( needs_update );
            u = obj.problem.u( needs_update );
            du_stop = obj.problem.stop_temperature - u_prev;
            du = u - u_prev;
            dt = obj.iterator.dt;
            t = obj.iterator.t_prev;
            sol_times = ( du_stop ./ du ) .* dt + t;
            
            % update
            obj.values( needs_update ) = sol_times;
        end
        
        function value = get.modulus( obj )
            value = sqrt( obj.values );
        end
    end
    
    properties ( Access = private )
        problem SolidificationProblem
        mesh
        iterator
    end
    
end

