classdef (Sealed) Segmentation < Process
    
    properties ( GetAccess = public, SetAccess = private )
        %% inputs
        mesh
        profile
        
        %% outputs
        array
        count
        segments
        
    end
    
    
    properties ( Access = public, Constant )
        
        BOUNDARY_VALUE = -1;
        
    end
    
    
    methods ( Access = public )
        
        function obj = Segmentation( varargin )
            
            obj = obj@Process( varargin{ : } );
            
        end
        
        
        function run( obj )
            
            if ~isempty( obj.results )
                obj.mesh = obj.results.get( Mesh.NAME );
                obj.profile = obj.results.get( EdtProfile.NAME );
            end
            
            assert( ~isempty( obj.mesh ) );
            assert( ~isempty( obj.profile ) );
            
            obj.printf( 'Segmenting...\n' );
            obj.array = Segmentation.generate_array( ...
                obj.profile.filtered_interior, ...
                obj.mesh ...
                );
            obj.count = Segmentation.get_segment_count( obj.array );
            obj.printf( '  Computing statistics...\n' );
            obj.segments = Segmentation.generate_segments( ...
                obj.array, ...
                obj.profile.scaled_interior, ...
                obj.mesh, ...
                obj.count ...
                );
            
        end
        
        
        function legacy_run( obj, profile, mesh )
            
            obj.mesh = mesh;
            obj.profile = profile;
            obj.run();
            
        end
        
        
        function write( obj, title, common_writer )
            
            common_writer.write_array( title, obj.to_array() );
            common_writer.write_table( title, obj.to_table() );
            
        end
        
        
        function neighbor_pairs = get_neighbor_pairs( obj, EdtProfile, Mesh )
            
            
            if obj.count == 1
                neighbor_pairs = SegmentPair.empty( 0 );
                return;
            end
            
            possible_pair_count = ( obj.count .* ( obj.count - 1 ) ) ./ 2;
            neighbor_pairs = cell( possible_pair_count, 1 );
            pair_count = 0;
            for first = 1 : obj.count
                
                for second = first + 1 : obj.count
                    
                    pair = SegmentPair( ...
                        obj, ...
                        [ first second ], ...
                        EdtProfile, ...
                        Mesh ...
                        );
                    if ~pair.are_neighbors
                        continue;
                    end
                    pair_count = pair_count + 1;
                    neighbor_pairs{ pair_count } = pair;
                    
                end
                
            end
            neighbor_pairs = [ neighbor_pairs{ : } ];
            
        end
        
        
        function segment_image = get_segment_image( obj, label )
            
            segment_image = ( obj.array == label );
            
        end
        
        
        function segment_image = get_segment_image_with_boundary( obj, label )
            
            segment_image = imdilate( ...
                obj.get_segment_image( label ), ...
                conndef( 3, 'maximal' ) ...
                );
            segment_image( obj.array == 0 ) = 0;
            
        end
        
        
        function clustered_segment_array = cluster_segment_array( ...
                obj, ...
                segment_labels, ...
                Mesh ...
                )
            
            segment_label_count = numel( segment_labels );
            clustered_segment_array = false( size( obj.array ) );
            for i = 1 : segment_label_count
                
                clustered_segment_array( obj.array == segment_labels( i ) ) ...
                    = true;
                
            end
            clustered_segment_array = ...
                imdilate( clustered_segment_array, conndef( 3, 'maximal' ) );
            clustered_segment_array( Mesh.exterior ) = 0;
            
        end
        
        
        function a = to_array( obj )
            
            a = obj.array;
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function dependencies = get_dependencies()
            
            dependencies = { ...
                Mesh.NAME, ...
                EdtProfile.NAME ...
                };
            
        end
        
        
        function name = NAME()
            
            name = mfilename( 'class' );
            
        end
        
    end
    
    
    methods ( Access = protected )
        
        function names = get_table_names( ~ )
            
            names = [ ...
                { 'number' } ...
                Segment.get_table_row_names() ...
                ];
            
        end
        
        
        function values = get_table_values( obj )
            
            values = cell( obj.count, obj.segments( 1 ).get_table_row_length() + 1 );
            for i = 1 : obj.count
                
                values( i, 1 ) = { i };
                values( i, 2 : end ) = obj.segments( i ).to_table_row();
                
            end
            
        end
        
        
        function summarized = is_summarized( ~ )
            
            summarized = true;
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function watershed_array = generate_array( edt_array, Mesh )
            %% INVERT
            edt_array( ~Mesh.interior ) = -inf;
            watershed_array = double( watershed( -edt_array ) );
            
            %% WATERSHED
            watershed_array( ~Mesh.interior ) = 0;
            % boundary marked separately from exterior
            watershed_array( Mesh.interior & ( watershed_array ) <= 0 ) ...
                = Segmentation.BOUNDARY_VALUE;
            
        end
        
        
        function count = get_segment_count( watershed_array )
            
            count = double( max( watershed_array( : ) ) );
            
        end
        
        
        function Segments = generate_segments( ...
                watershed_array, ...
                edt_array, ...
                mesh, ...
                count ...
                )
            
            Segments = Segment.empty( count, 0 );
            for i = 1 : count
                
                Segments( i ) = Segment( ...
                    edt_array, ...
                    watershed_array == i, ...
                    mesh ...
                    );
                
            end
            
        end
        
    end
    
end
