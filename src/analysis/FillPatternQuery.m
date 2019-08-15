classdef FillPatternQuery < handle
    
    properties ( SetAccess = private )
    end
    
    methods
        % - @interior is a 3D logical array representing the interior of the
        % mesh.
        % - @gates is a connected-components struct (i.e. from bwconncomp)
        % indicating the indices which represent ingates in the mesh.
        % INITIAL VELOCITY?
        function obj = FillPatternQuery( interior, gates )
            % Find surface of interior inside gates.
            % Insert gate voxels into priority queue.
            % Set step = 0
            % while ??
            %  Increment step
            %  Pop current from queue
            %  For each current
            %   Current voxel = step
            %   Find next
            %   If next is cavity and not patterned
            %    Push on queue
            %   If next is cavity and in queue
            %    Calculate resultant vector
            %    Calculate new filling step
            %    Push on queue
            %   If next is mold or already filled
            %    Determine local mold orientation
            %    Calculate step delay of empty voxels based on position in
            %    neighborhood
            %    Calculate resultant vector of neighbor voxels
            %    If neighbor in queue
            %     SAME AS CAVITY IN QUEUE
            %    Else
            %     Increment current
        end
    end
    
    properties ( Access = private )
        step_counter(1,1) double
        pq BinaryMinHeap
        volume_fraction(:,:,:) double
        step(:,:,:) double
        dstep(:,:,:) double
        n_filling(:,:,:) uint8
        flow(3,:,:,:) double
    end
    
    methods ( Access = private )
        function initialize_gates( obj, gates, gate_neighbors )
            obj.volume_fraction( gates ) = 1;
            obj.step( gates ) = 1;
            obj.flow( 3*gates - (0:2) ) = 
            % handle gate flow here
            obj.dstep( gates ) = 1;
            
        end
        
        % when popped, reset nfilling
        function next_empty( obj, current, next )
            obj.volume_fraction( next ) = obj.volume_fraction( current );
            obj.step( next ) = obj.step( current ) + obj.dstep( current );
            obj.flow( 3*next - (0:2) ) = obj.flow( 3*current - (0:2) );
            obj.dstep( next ) = obj.dstep( current );
            obj.n_filling( next ) = obj.n_filling( next ) + 1;
        end
        
        % needs queue adjustment
        % when popped, reset nfilling
        function next_filled( obj, current, next )
            obj.volume_fraction( next ) = obj.volume_fraction( current );
            obj.step( next ) = obj.calculate_multistep( ...
                obj.step_counter, ...
                obj.step( current ) + obj.dstep( current ), ...
                obj.step( next ), ...
                obj.n_filling( next ) ...
                );
            obj.flow( 3*next - (0:2) ) = obj.calculate_multiflow( ...
                obj.flow( 3*current - (0:2) ), ...
                obj.dstep( current ), ...
                obj.flow( 3*next - (0:2) ), ...
                obj.dstep( next ) ...
                );
            obj.dstep( next ) = obj.step( next ) - obj.step_counter;
            obj.n_filling( next ) = obj.n_filling( next ) + 1;
        end
        
        % when popped, reset nfilling
        function next_obstructed_empty( obj, current, current_subs, empty_neighbors, empty_neighbor_subs )
            dp = current_subs - empty_neighbor_subs;
            c = dot( obj.flow( 3*empty_neighbors + (0:2) ), dp );
            c = c + abs( min( c ) );
            c = c ./ sum( c );
            obj.volume_fraction( empty_neighbors ) = obj.volume_fraction( current ) .* c;
            obj.step( empty_neighbors ) = obj.step( current ) + obj.dstep( current ) .* obj.volume_fraction( empty_neighbors );
            obj.flow( 3*empty_neighbors - (0:2) ) = dp;
            obj.dstep( empty_neighbors ) = obj.step( empty_neighbors ) - obj.step( current );
            obj.n_filling( next ) = obj.n_filling( next ) + 1;
        end
        
        % needs queue adjustment
        % when popped, reset nfilling
        function next_obstructed_filled( obj, current, current_subs, filled_neighbors, filled_neigbhor_subs )
            dp = current_subs - filled_neigbhor_subs;
            c = dot( obj.flow( 3*filled_neighbors + (0:2) ), dp );
            c = c + abs( min( c ) );
            c = c ./ sum( c );
            obj.volume_fraction( filled_neighbors ) = obj.volume_fraction( filled_neighbors ) ...
                + obj.volume_fraction( current ) .* c;
            obj.step( filled_neighbors ) = obj.calculate_multistep( ...
                obj.step_counter, ...
                obj.step( current ) + obj.dstep( current ) .* obj.volume_fraction( empty_neighbors ), ...
                obj.step( filled_neighbors ), ...
                obj.n_filling( next ) ...
                );
            obj.flow( 3*next - (0:2) ) = obj.calculate_multiflow( ...
                dp, ...
                obj.dstep( current ), ...
                obj.flow( 3*next - (0:2) ), ...
                obj.dstep( next ) ...
                );
            obj.dstep( next ) = obj.step( next ) - obj.step_counter;
            obj.n_filling( next ) = obj.n_filling( next ) + 1;
        end
    end
    
    methods ( Access = private, Static )
        function out = calculate_multistep( current_step, added_step, fill_step, fill_count )
            out = current_step + update_harmmean( ...
                added_step - current_step, ...
                fill_step - current_step, ...
                fill_count ...
                );
        end
        
        function out = calculate_multiflow( new_flow, new_dstep, fill_flow, fill_dstep )
            out = update_weighted_mean( ...
                new_flow, ...
                new_dstep, ...
                fill_flow, ...
                fill_dstep ...
                );
        end
    end
    
end

