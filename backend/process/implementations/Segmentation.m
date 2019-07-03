classdef (Sealed) Segmentation < Process
    
    properties ( GetAccess = public, SetAccess = private )
        %% inputs
        mesh
        geometric_profile
        use_thermal_profile
        thermal_profile
        
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
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
                
                geometric_profile_key = ProcessKey( GeometricProfile.NAME );
                obj.geometric_profile = obj.results.get( geometric_profile_key );
            end
            assert( ~isempty( obj.mesh ) );
            assert( ~isempty( obj.geometric_profile ) );
            
            if ~isempty( obj.options )
                FALLBACK_USE_THERMAL_PROFILE = false;
                obj.use_thermal_profile = obj.options.get( ...
                    'processes.thermal_profile.use', ...
                    FALLBACK_USE_THERMAL_PROFILE ...
                    );
            end
            assert( ~isempty( obj.use_thermal_profile ) );
            
            if obj.use_thermal_profile
                thermal_profile_key = ProcessKey( ThermalProfile.NAME );
                obj.thermal_profile = obj.results.get( thermal_profile_key );
                assert( ~isempty( obj.thermal_profile ) );
            end
            
            obj.printf( 'Segmenting...\n' );
            if obj.use_thermal_profile
                segmentation_base = obj.thermal_profile.thermal_modulus_filtered; % modulus-like
            else
                segmentation_base = obj.geometric_profile.filtered_interior;
            end
            segmentation_array = Segmentation.generate_array( ...
                segmentation_base, ...
                obj.mesh ...
                );
            obj.count = Segmentation.get_segment_count( segmentation_array );
            obj.printf( '  Computing statistics...\n' );
            obj.segments = obj.generate_segments( ...
                segmentation_base, ...
                segmentation_array, ...
                obj.geometric_profile.scaled_interior, ...
                obj.mesh, ...
                obj.count ...
                );
            obj.array = segmentation_array;
            
        end
        
        
        function legacy_run( obj, geometric_profile, mesh, thermal_profile )
            
            obj.mesh = mesh;
            obj.geometric_profile = geometric_profile;
            if 3 < nargin
                obj.use_thermal_profile = true;
                obj.thermal_profile = thermal_profile;
            end
            obj.run();
            
        end
        
        
        function write( obj, title, common_writer )
            
            common_writer.write_array( title, obj.to_array() );
            common_writer.write_table( title, obj.to_table() );
            
        end
        
        
        function neighbor_pairs = get_neighbor_pairs( obj, GeometricProfile, Mesh )
            
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
                        GeometricProfile, ...
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
    
    
    methods ( Access = private )
        
        function Segments = generate_segments( ...
                obj, ...
                base_array, ...
                watershed_array, ...
                edt_array, ...
                mesh, ...
                count ...
                )
            
            Segments = Segment.empty( count, 0 );
            for i = 1 : count
                
                segment_binary_array = ( watershed_array == i );
                
                if obj.use_thermal_profile
                    base_threshold = ...
                        obj.thermal_profile.thermal_modulus_filter_threshold;
                else
                    base_array = edt_array;
                    base_threshold = ...
                        obj.geometric_profile.filter_amount;
                end
                
                Segments( i ) = Segment( ...
                    base_array, ...
                    base_threshold, ...
                    edt_array, ...
                    segment_binary_array, ...
                    mesh ...
                    );
                
            end
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function watershed_array = generate_array( base_array, Mesh )
            %% INVERT
            base_array( ~Mesh.interior ) = -inf;
            watershed_array = double( watershed( -base_array ) );
            
            %% WATERSHED
            watershed_array( ~Mesh.interior ) = 0;
            % boundary marked separately from exterior
            watershed_array( Mesh.interior & ( watershed_array ) <= 0 ) ...
                = Segmentation.BOUNDARY_VALUE;
            
        end
        
        
        function count = get_segment_count( watershed_array )
            
            count = double( max( watershed_array( : ) ) );
            
        end
        
    end
    
end
