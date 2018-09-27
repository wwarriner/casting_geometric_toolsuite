classdef (Sealed) TubePath < ProcessHelper
    
    properties ( GetAccess = public, SetAccess = private )
        
        path_distance
        path_length
        path
        
    end
    
    
    methods ( Access = public )
        
        function obj = TubePath( ...
                segmentation, ...
                mesh, ...
                segment_pair ...
                )
            
            path_indices = TubePath.generate_path_indices( ...
                segmentation, ...
                segment_pair ...
                );
            obj.path = TubePath.generate_path( ...
                segmentation.array, ...
                mesh.element.length, ...
                mesh.origin, ...
                path_indices ...
                );
            obj.path_distance = ...
                TubePath.compute_path_distance( obj.path );
            obj.path_length = ...
                TubePath.compute_path_length( obj.path_distance );
            
        end
        
        
        function samples = sample_path_parameter( ~, sample_count )
            
            samples = linspace( ...
                0, ...
                1, ...
                sample_count ...
                );
            
        end
        
        
        function samples = sample_path_distance( obj, sample_count )
            
            samples = linspace( ...
                obj.path_distance( 1 ), ...
                obj.path_distance( end ), ...
                sample_count ...
                );
            
        end
        
        
        % recommended point_count_spacing = 0.5
        function spline_breaks = get_spline_breaks( obj, break_count )
            
            spline_breaks = obj.sample_path_distance( break_count );
            
        end
        
        
        % recommended parameter_query_spacing = 2
        function spline_queries = get_spline_queries( obj, query_count )
            
            spline_queries = obj.sample_path_distance( query_count );
            
        end
        
        
        function parameter_queries = get_parameter_queries( obj, query_count )
            
            spline_queries = obj.get_spline_queries( query_count );
            parameter_queries = rescale( spline_queries, 0, 1 );
            
        end
        
        
        function tr = to_table_row( obj )
            
            tr = { obj.path_length };
            assert( numel( tr ) == obj.get_table_row_length() );
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function trn = get_table_row_names()
        
            trn = { 'path_length' };
            
        end
        
    end
    
    
    % trace_path_indices
    methods ( Access = private, Static )
        
        function path_indices = generate_path_indices( ...
                segmentation, ...
                segment_pair ...
                )
            
            path_indices = TubePath.trace_path_indices( ...
                segmentation, ...
                segment_pair ...
                );
            path_indices{ 1 } = TubePath.prepare_front_path_indices( ...
                path_indices{ 1 } ...
                );
            path_indices = [ path_indices{ 1 } path_indices{ 2 }];
            
        end
        
        
        function path_indices = trace_path_indices( segmentation, segment_pair )
            
            segment_count = length( segment_pair.labels );
            path_indices = cell( segment_count, 1 );
            for i = 1 : segment_count
                
                segment = segmentation.get_segment_image_with_boundary( ...
                    segment_pair.labels( i ) ...
                    );
                path_indices{ i } = TubePath.trace_segment_path_indices( ...
                    segment, ...
                    segment_pair.seeds{ i }, ...
                    segment_pair.boundary_index ...
                    );
                
            end
            
        end
        
        
        function path_indices = trace_segment_path_indices( ...
                segment, ...
                seed, ...
                boundary_index ...
                )
            
            % todo: have path follow edt gradient
            % todo: use thinning to choose a path instead of bfs
            
            PAD = [ 1 1 1 ];
            geodesic = TubePath.prepare_geodesic( segment, seed, PAD );
            index_changer = IndexChanger( ...
                size( segment ), ...
                size( geodesic ), ...
                PAD ...
                );
            
            seed_sub = index_changer.oldind2newsub( seed );
            neighbor_offsets = generate_neighbor_offsets( geodesic );
            initial_index = index_changer.change( boundary_index );
            path_indices = TubePath.determine_segment_path_indices( ...
                geodesic, ...
                seed_sub, ...
                neighbor_offsets, ...
                initial_index, ...
                index_changer ...
                );
            
        end
        
        
        function geodesic_array = prepare_geodesic( segment, seed, pad )
            
            geodesic_array = bwdistgeodesic( ...
                logical( segment ), ...
                seed, ...
                'quasi-euclidean' ...
                );
            geodesic_array( ~segment ) = inf;
            geodesic_array = padarray( ...
                geodesic_array, ...
                pad, ...
                inf, ...
                'both' ...
                );
            
        end
        
        
        function path_indices = determine_segment_path_indices( ...
                geodesic, ...
                seed_sub, ...
                neighbor_offsets, ...
                initial_position, ...
                index_changer ...
                )
            
            position = 1;
            path_indices( position ) = initial_position;
            previous_position = initial_position;
            while( geodesic( previous_position ) > 1 )
                
                min_geo_indices = TubePath.get_min_neighbor_indices( ...
                    neighbor_offsets, ...
                    previous_position, ...
                    geodesic ...
                    );
                previous_position = TubePath.determine_next_index( ...
                    min_geo_indices, ...
                    seed_sub, ...
                    size( geodesic ) ...
                    );
                position = position + 1;
                path_indices( position ) = previous_position;
                
            end
            path_indices = arrayfun( ...
                @(x) index_changer.revert( x ), ...
                path_indices );
            
        end
        
        
        function min_neighbor_indices = get_min_neighbor_indices( ...
                offsets, ...
                previous, ...
                values ...
                )
            
            neighbors = previous + offsets;
            neighbor_values = values( neighbors );
            min_value = min( neighbor_values );
            min_neighbor_indices = neighbors( neighbor_values == min_value );
            
        end
        
        
        function next_index = determine_next_index( ...
                min_indices, ...
                seed_sub, ...
                array_size ...
                )
            
            index_count = length( min_indices( : ) );
            if index_count == 1
                
                next_index = min_indices;
                
            elseif index_count > 1
                
                next_index = TubePath.compute_closest_index( ...
                    min_indices, ...
                    seed_sub, ...
                    array_size ...
                    );
                
            else
                
                error( 'no last index found while determining path' );
                
            end
            
        end
        
        
        function closest = compute_closest_index( ...
                indices, ...
                compare_subs, ...
                array_size ...
                )
            
            index_count = length( indices( : ) );
            distances = zeros( index_count, 1 );
            for i = 1 : index_count
                
                subs = ind2sub_vec( array_size, indices( i ) );
                distances( i ) = norm( subs - compare_subs );
                
            end
            [ ~, min_distance ] = min( distances( : ) );
            closest = indices( min_distance );
            
        end
        
        
        function front_path_indices = prepare_front_path_indices( ...
                front_path_indices ...
                )
            
            front_path_indices = flip( front_path_indices );
            front_path_indices = front_path_indices( 1 : end - 1 );
            
        end
        
    end
    
    
    % generate_path
    methods ( Access = private, Static )
        
        function path = generate_path( ...
                segmentation_array, ...
                element_length, ...
                origin, ...
                path_indices ...
                )
            
            [ X, Y, Z ] = arrayfun( ...
                @(i) ind2sub( size( segmentation_array ), i ), ...
                path_indices.' ...
                );
            path = [ X Y Z ].';
            path = ( path .* element_length ) + origin.';
            
        end
        
        
        function path_distance = compute_path_distance( path )
            
            distances = vecnorm( diff( path, 1, 2 ), 2, 1 );
            path_distance = [ 0 cumsum( distances ) ];
            
        end
        
        
        function path_length = compute_path_length( path_distance )
            
            path_length = path_distance( end );
            
        end
        
    end
    
end

