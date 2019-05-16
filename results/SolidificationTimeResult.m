classdef SolidificationTimeResult < Result
    
    methods ( Access = public )
        
        function obj = SolidificationTimeResult( ...
                shape, ...
                stop_temperature ...
                )
            
            assert( isscalar( stop_temperature ) );
            assert( isa( stop_temperature, 'double' ) );
            assert( 0 < stop_temperature );
            
            obj.stop_temperature = stop_temperature;
            obj.values = nan( shape );
            
        end
        
        
        function update( ...
                obj, ...
                mesh, ...
                physical_properties, ...
                iterator, ...
                problem ...
                )
            
            % setup
            u = problem.get_temperature();
            u_prev = problem.get_previous_temperature();
            times = iterator.get_times();
            t = times.get_time( 1 );
            t_prev = times.get_time( 2 );
            
            % compute
            sol_times = ( ( obj.stop_temperature - u_prev ) ./ ...
                ( u - u_prev ) .* ...
                ( t - t_prev ) ) + ...
                t_prev;
            
            % update
            is_melt = physical_properties.is_primary_melt( mesh );
            past_threshold = u <= obj.stop_temperature;
            unrecorded = isnan( obj.values );
            needs_update = is_melt & past_threshold & unrecorded;
            obj.values( needs_update ) = sol_times( needs_update );
            
        end
        
        
        function field = get_scalar_field( obj )
            
            field = obj.values;
            
        end
        
        
        function finished = is_finished( obj, fdm_mesh, melt_id )
            
            finished = all( fdm_mesh ~= melt_id | obj.values > 0 );
            
        end
        
        
        function time = get_final_time( obj )
            
            time = max( obj.values( : ) );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        problem
        stop_temperature
        values
        
    end
    
end

