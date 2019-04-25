classdef (Sealed) Feeders < Process & matlab.mixin.Copyable
    
    properties ( GetAccess = public, SetAccess = private )
        %% inputs
        mesh
        segmentation
        
        %% outputs
        count
        feeders
        envelope        
        feeder_mesh
        fv
        
    end
    
    
    methods ( Access = public )
        
        function obj = Feeders( varargin )
            
            obj = obj@Process( varargin{ : } );
            
        end
        
        
        function run( obj )
            
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
                
                segmentation_key = ProcessKey( Segmentation.NAME );
                obj.segmentation = obj.results.get( segmentation_key );
            end
            assert( ~isempty( obj.mesh ) );
            assert( ~isempty( obj.segmentation ) );
            
            obj.printf( 'Generating feeders...\n' );
            obj.count = Feeders.get_feeder_count( obj.segmentation );
            obj.feeders = Feeders.generate_feeders( ...
                obj.segmentation, ...
                obj.mesh, ...
                obj.count ...
                );
            obj.update( obj.mesh );
            
        end
        
        
        function legacy_run( obj, segmentation, mesh )
            
            obj.mesh = mesh;
            obj.segmentation = segmentation;
            obj.run();
            
        end
        
        
        function volume = get_total_exclusive_volume( obj )
            
            volume = sum( obj.get_exclusive_volumes() );
            
        end
        
        
        function volumes = get_exclusive_volumes( obj )
            
            volumes = [ obj.feeders.exclusive_volume ];
            
        end
        
        
        function volume = get_total_intersection_volume( obj )
            
            volume = sum( [ obj.feeders.intersection_volume ] );
            
        end
        
        
        function area = get_total_interface_area( obj )
            
            area = sum( [ obj.feeders.interface_area ] );
            
        end
        
        
        function height = get_total_rigged_height( obj, dimension )
            
            height = obj.envelope.lengths( dimension );
            
        end
        
        
        function ratios = get_accessibility_ratios( obj )
            
            ratios = [ obj.feeders.accessibility_ratio ];
            
        end
        
        
        function clone = rotate( obj, rotator, mesh )
            
            clone = obj.copy();
            for i = 1 : clone.count
                
                clone.feeders( i ) = ...
                    obj.feeders( i ).rotate( rotator, mesh );
                
            end
            clone.update( mesh );
            
        end
        
        
        function fvs = rotate_fvs_only( obj, rotator )
            
            clone = obj.copy();
            fvs = cell( clone.count, 1 );
            for i = 1 : clone.count
                
                fvs{ i } = obj.feeders( i ).rotate_fv_only( rotator );
                
            end
            
        end
        
        
        function write( obj, title, common_writer )
            
            common_writer.write_fv_sequence( title, obj.to_fvs() );
            common_writer.write_table( title, obj.to_table() );
            
        end
        
        
        function fvs = to_fvs( obj )
            
            fvs = { obj.feeders.fv };
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function name = NAME()
            
            [ ~, name ] = fileparts( mfilename( 'full' ) );
            
        end
        
    end
    
    
    methods ( Access = protected )
        
        function names = get_table_names( ~ )
            
            names = [ ...
                { 'number' } ...
                Feeder.get_table_row_names() ...
                ];
            
        end
        
        
        function values = get_table_values( obj )
            
            values = cell( obj.count, obj.feeders( 1 ).get_table_row_length() + 1 );
            for i = 1 : obj.count
                
                values( i, 1 ) = { i };
                values( i, 2 : end ) = obj.feeders( i ).to_table_row();
                
            end
            
        end
        
        
        function summarized = is_summarized( ~ )
            
            summarized = true;
            
        end
        
    end
    
    
    properties ( Access = private, Constant )
        
        INACCESSIBILITY_VOLUME_RATIO_THRESHOLD = 0.1;
        
    end
    
    
    methods ( Access = private )
        
        function update( obj, mesh )
            
            obj.feeder_mesh = obj.generate_feeder_mesh( mesh );
            obj.fv = obj.generate_fv( obj.feeders, obj.count );
            obj.envelope = ...
                MeshEnvelope( obj.fv );
            
        end
        
        
        function feeder_mesh = generate_feeder_mesh( obj, mesh )
            
            feeder_mesh = zeros( size( mesh.interior ) );
            for i = 1 : obj.count
                
                feeder_mesh = feeder_mesh | obj.feeders( i ).feeder_mesh;
                
            end
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        
        function count = get_feeder_count( segmentation )
            
            count = segmentation.count;
            
        end
        
        
        function feeders = generate_feeders( ...
                segmentation, ...
                mesh, ...
                count ...
                )
            
            feeders = Feeder.empty( count, 0 );
            for i = 1 : count
                
                feeders( i ) = Feeder( segmentation.segments( i ), mesh );
                
            end
            
        end
        
        
        function fv = generate_fv( ...
                feeders, ...
                count ...
                )
            
            fv = empty_fv();
            for i = 1 : count
                
                fv = merge_fv( fv, feeders( i ).fv );
                
            end
            
        end
        
    end
    
end

