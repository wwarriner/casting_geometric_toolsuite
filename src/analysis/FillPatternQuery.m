classdef FillPatternQuery < handle
    
    properties ( SetAccess = private )
    end
    
    methods
        % - @interior is a 3D logical array representing the interior of the
        % mesh.
        % - @gates is a connected-components struct (i.e. from bwconncomp)
        % indicating the indices which represent ingates in the mesh.
        % INITIAL VELOCITY?
        function obj = FillPatternQuery( interior, normals, gates )
            obj.current_step = 0;
            obj.initialize_gates( normals, find( gates & interior ) ); %#ok<FNDSB>
            while ~obj.done()
                current = obj.pop();
                obj.reset( current );
                next = obj.get_next_flow( current );
                filled = obj.is_filled( next );
                obstructed = obj.is_obstructed( next );
                obj.next_empty( ...
                    current( ~filled & ~obstructed ), ...
                    next( ~filled & ~obstructed ) ...
                    );
                obj.next_filled( ...
                    current( filled & ~obstructed ), ...
                    next( filled & ~obstructed ) ...
                    );
                if any( obstructed )
                    current = current( obstructed );
                    next = next( obstructed );
                    current_subs = obj.ind2sub( current );
                    neighbors = obj.get_neighbors_not_next( current, next );
                    neighbor_subs = obj.ind2sub( neighbors );
                    obj.next_obstructed_empty( ...
                        current( ~filled ), ...
                        current_subs( ~filled, : ), ...
                        neighbors( ~filled ), ...
                        neighbor_subs( ~filled, : ) ...
                        );
                    obj.next_obstructed_filled( ...
                        current( filled ), ...
                        current_subs( filled, : ), ...
                        neighbors( filled ), ...
                        neighbor_subs( filled, : ) ...
                        );
                end
                
            end
            
            % initialize gates
            % while not done
            %  pop current from queue
            %  find next from current flow direction
            %  if next is NOT OBSTRUCTED
            %   if next is NOT IN QUEUE
            %    calculate next info
            %    push on queue
            %   else (IN QUEUE)
            %    recalculate next info
            %    update on queue
            %  else (OBSTRUCTED)
            %   get unobstructed neighbors
            %   compute neighbor splash pattern
            %   for each unobstructed neighbor
            %    if neighbor is NOT IN QUEUE
            %     calculate neighbor info
            %     push on queue
            %    else (IN QUEUE)
            %     recalculate neighbor info
            %     update on queue
            %    end
            %   end
            %  end
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
        function initialize_gates( obj, normals, gates )
            obj.volume_fraction( gates ) = 1;
            obj.step( gates ) = 1;
            p = permute( normals, [ 4 1 2 3 ] );
            obj.flow( 3*gates - (0:2) ) = -p( 3*gates - (0:2) );
            obj.dstep( gates ) = 1;
            obj.enqueue( gates );
        end
        
        % when popped, reset nfilling
        function next_empty( obj, current, next )
            obj.volume_fraction( next ) = obj.volume_fraction( next ) + obj.volume_fraction( current );
            obj.step( next ) = obj.step( current ) + obj.dstep( current );
            obj.flow( 3*next - (0:2) ) = obj.flow( 3*current - (0:2) );
            obj.dstep( next ) = obj.dstep( current );
            obj.n_filling( next ) = obj.n_filling( next ) + 1;
            obj.enqueue( next );
        end
        
        % needs queue adjustment
        % when popped, reset nfilling
        function next_filled( obj, current, next )
            obj.volume_fraction( next ) = obj.volume_fraction( next ) + obj.volume_fraction( current );
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
            obj.update( next );
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
            obj.n_filling( empty_neighbors ) = obj.n_filling( empty_neighbors ) + 1;
            obj.enqueue( empty_neighbors );
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
            obj.flow( 3*filled_neighbors - (0:2) ) = obj.calculate_multiflow( ...
                dp, ...
                obj.dstep( current ), ...
                obj.flow( 3*filled_neighbors - (0:2) ), ...
                obj.dstep( filled_neighbors ) ...
                );
            obj.dstep( filled_neighbors ) = obj.step( filled_neighbors ) - obj.step_counter;
            obj.n_filling( filled_neighbors ) = obj.n_filling( filled_neighbors ) + 1;
            obj.update( filled_neighbors );
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

