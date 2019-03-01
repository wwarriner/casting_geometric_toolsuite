classdef SolidificationTime < handle
    
    properties ( GetAccess = public, SetAccess = private )
        
        values
        
    end
    
    
    methods ( Access = public )
        
        function obj = SolidificationTime( shape )
            
            obj.values = zeros( shape );
            
        end
        
        
        function update_nd( obj, fdm_mesh, melt_id, pp, u_prev, u_next, simulation_time, simulation_time_step )
            
            fs_prev = pp.lookup_values( melt_id, pp.FS_INDEX, u_prev );
            fs_next = pp.lookup_values( melt_id, pp.FS_INDEX, u_next );
            melt_fe = pp.get_feeding_effectivity( melt_id );
            prev_time = simulation_time - simulation_time_step;
            
            sol_times = ( melt_fe - fs_prev ) ./ ( fs_next - fs_prev ) .* ...
                ( simulation_time - prev_time ) + prev_time;
            updates = fdm_mesh == melt_id & ...
                fs_next >= melt_fe & ...
                obj.values == 0;
            obj.values( updates ) = sol_times( updates );
            
        end
        
        
        function finished = is_finished( obj, fdm_mesh, melt_id )
            
            finished = all( fdm_mesh ~= melt_id | obj.values > 0 );
            
        end
        
        
        function manipulate( obj, fn )
            
            obj.values = fn( obj.values );
            
        end
        
        
        function time = get_final_time( obj )
            
            time = max( obj.values( : ) );
            
        end
        
    end
    
end

