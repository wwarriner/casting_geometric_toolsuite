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
        
        NAME = 'segmentation'
        
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
            
            % TODO can remove padding I think, test first
            
            % pad interior and edt to prepare for pseudo-masked watershed
            watershed_interior = ...
                Segmentation.pad_for_watershed( Mesh.interior );
            watershed_array = ...
                Segmentation.pad_for_watershed( edt_array );
            
            % pseudo-mask interior
            %{
                Note that we assign -inf (becomes -inf later) to forcibly 
                divide interior segments from exterior segments.
            %}
            watershed_buffer = ...
                imdilate( watershed_interior, conndef( 3, 'maximal' ) ) ...
                & ~watershed_interior;
            watershed_array( watershed_buffer ) = -inf;
            
            % watershed
            watershed_array = uint16( watershed( -watershed_array ) );

            % watershed boundary
            watershed_array( ~watershed_interior ) = 0;
            
            % reorganizing labels
            interior_segments = unique( watershed_array );
            interior_count = length( interior_segments ) - 1;
            lut_count = double( intmax( 'uint16' ) ) + 1;
            lut = uint16( zeros( lut_count, 1 ) );
            lut( interior_segments + 1 ) = 0 : interior_count;
            watershed_array = intlut( watershed_array, lut );
            
            % assign boundary
            if interior_count > intmax( 'int16' )
                warning( 'Too many segments, clipping large values...\n' );
            end
            % R2017b clips signed integer values.
            % e.g. intmax( 'int16' ) + 1 == intmax( 'int16' );
            % works on conversion as well
            watershed_array = int16( watershed_array );
            watershed_array( ...
                watershed_interior ...
                & watershed_array <= 0 ...
                ) ...
                = -1;
            
            % unpad
            watershed_array = watershed_array( ...
                2 : end - 1, ...
                2 : end - 1, ...
                2 : end - 1 ...
                );
            
            
        end
        
        
        function padded = pad_for_watershed( array )
            
            padded = padarray( array, ones( ndims( array ), 1 ), 'both' );
            
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
