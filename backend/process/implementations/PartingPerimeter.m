classdef (Sealed) PartingPerimeter < Process
    
    properties ( GetAccess = public, SetAccess = private )
        %% inputs
        mesh
        do_optimize_parting_line
        
        %% outputs
        projected_area
        projected_perimeter
        perimeter
        jog_free_perimeter
        
        max_slice
        min_slice
        heights
        
        draw
        perimeter_length
        
        count
        jog_free_count
        
        length_ratio
        area_ratio
        draw_ratio
        
        %% optional outputs
        parting_line
        flatness
        
    end
    
    
    properties ( Access = public, Constant )
        
        NAME = 'parting_perimeter'
        
    end
    
    
    methods ( Access = public )
        
        function obj = PartingPerimeter( varargin )
            
            obj = obj@Process( varargin{ : } );
            
        end
        
        
        function run( obj )
            
            if ~isempty( obj.results )
                obj.mesh = obj.results.get( Mesh.NAME );
            end
            
            if ~isempty( obj.options )
                obj.do_optimize_parting_line = obj.options.do_optimize_parting_line;
            end
            
            if isempty( obj.do_optimize_parting_line )
                obj.do_optimize_parting_line = false;
            end
            
            assert( ~isempty( obj.mesh ) );
            assert( ~isempty( obj.parting_dimension ) );
            assert( ~isempty( obj.do_optimize_parting_line ) );
            
            obj.printf( ...
                'Locating parting perimeter for axis %d...\n', ...
                obj.parting_dimension ...
                );
            [ rotated_interior, inverse ] = rotate_to_dimension( ...
                obj.parting_dimension, ...
                obj.mesh.interior, ...
                PartingPerimeter.ANALYSIS_DIMENSION ...
                );
            projected_interior = ...
                PartingPerimeter.identify_projected_interior( ...
                rotated_interior ...
                );
            obj.projected_area = obj.mesh.to_stl_area( sum( projected_interior( : ) ) );
            obj.area_ratio = obj.projected_area ./ obj.mesh.to_stl_area( obj.mesh.get_cross_section_area( obj.parting_dimension ) );
            obj.projected_perimeter = ...
                PartingPerimeter.identify_projected_perimeter( ...
                projected_interior ...
                );
            [ obj.max_slice, obj.min_slice ] = ...
                PartingPerimeter.compute_unprojection_bounds( ...
                rotated_interior, ...
                obj.projected_perimeter ...
                );
            unprojected_perimeter = PartingPerimeter.unproject_perimeter( ...
                rotated_interior, ...
                obj.projected_perimeter, ...
                obj.max_slice, ...
                obj.min_slice ...
                );
            obj.perimeter = rotate_from_dimension( ...
                unprojected_perimeter, ...
                inverse ...
                );
            
            obj.printf( '  Finding jog-free perimeter...\n' );
            projected_cc = bwconncomp( obj.projected_perimeter );
            [ unprojected_jog_free, jog_height_voxel_units ] = ...
                PartingPerimeter.compute_jog_free_perimeter( ...
                unprojected_perimeter, ...
                projected_cc, ...
                obj.min_slice, ...
                obj.max_slice ...
                );
            unprojected_jog_free = rotate_from_dimension( ...
                unprojected_jog_free, ...
                inverse ...
                );
            JOG_FREE_VALUE = 2;
            obj.perimeter( logical( unprojected_jog_free ) ) = JOG_FREE_VALUE;
            
            if obj.do_optimize_parting_line
                obj.printf( '  Optimizing parting line...\n' );
                
                outer_perimeter = bwmorph( bwmorph( bwmorph( bwperim( imfill( obj.projected_perimeter, 'holes' ) ), 'thin', inf ), 'spur' ), 'thin', inf );
                
                [ loop_indices, right_side_distances ] = ...
                    obj.order_indices_by_loop( outer_perimeter);
                pl = PartingLine( ...
                    obj.min_slice( loop_indices ), ...
                    obj.max_slice( loop_indices ), ...
                    right_side_distances ...
                    );
                
                path = nan( size( outer_perimeter ) );
                path( loop_indices ) = round( pl.parting_line );
                unprojected_parting_line = obj.unproject_perimeter( ...
                    rotated_interior, ...
                    outer_perimeter, ...
                    path, ...
                    path ...
                    );
                unprojected_parting_line = rotate_from_dimension( ...
                    unprojected_parting_line, ...
                    inverse ...
                    );
                PARTING_LINE_VALUE = 3;
                obj.perimeter( unprojected_parting_line > 0 ) = PARTING_LINE_VALUE;
                obj.flatness = pl.flatness;
                
            end
            
            obj.printf( '  Computing statistics...\n' );
            obj.heights = obj.mesh.to_stl_units( obj.max_slice - obj.min_slice + 1 );
            cc = bwconncomp( obj.projected_perimeter );
            obj.count = cc.NumObjects;
            rp = regionprops( imfill( projected_interior, 'holes' ), 'perimeter' );
            obj.perimeter_length = obj.mesh.to_stl_units( sum( [ rp.Perimeter ] ) );
            obj.draw = PartingPerimeter.compute_draw( ...
                jog_height_voxel_units, ...
                projected_cc, ...
                obj.min_slice, ...
                obj.max_slice, ...
                obj.mesh.scale, ...
                obj.mesh.get_extrema( PartingPerimeter.ANALYSIS_DIMENSION ) ...
                );
            largest_length = obj.mesh.to_stl_units( obj.mesh.get_largest_length() );
            obj.draw_ratio = 2 .* obj.draw / largest_length;
            obj.length_ratio = obj.perimeter_length ./ largest_length;
            cc = bwconncomp( squeeze( any( obj.jog_free_perimeter, obj.parting_dimension ) ) );
            obj.jog_free_count = cc.NumObjects;
            
        end
        
        
        function legacy_run( obj, mesh, parting_dimension, do_optimize_parting_line )
            
            if nargin < 4
                do_optimize_parting_line = false;
            end
            obj.mesh = mesh;
            obj.parting_dimension = parting_dimension;
            obj.do_optimize_parting_line = do_optimize_parting_line;
            obj.run();
            
        end
        
        
        function jog_free_exists = has_jog_free( obj )
            
            jog_free_exists = ( obj.jog_free_count == obj.count );
            
        end
        
        
        function write( obj, title, common_writer )
            
            common_writer.write_array( title, obj.perimeter );
            common_writer.write_table( title, obj.to_table() );
            
        end
        
        
        function a = to_array( obj )
            
            a = obj.perimeter + obj.jog_free_perimeter;
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function dependencies = get_dependencies()
            
            dependencies = { ...
                Mesh.NAME ...
                };
            
        end
        
        
        function orientation_dependent = is_orientation_dependent()
            
            orientation_dependent = true;
            
        end
        
    end
    
    
    methods ( Access = protected )
        
        function names = get_table_names( obj )
            
            names = { ...
                'draw_ratio', ...
                'length_ratio', ...
                'area_ratio', ...
                'count', ...
                'jog_free_count', ...
                };
            if obj.do_optimize_parting_line
                names = [ names 'flatness' ];
            end
            
        end
        
        
        function values = get_table_values( obj )
            
            values = { ...
                obj.draw_ratio, ...
                obj.length_ratio, ...
                obj.area_ratio, ...
                obj.count, ...
                obj.jog_free_count ...
                };
            if obj.do_optimize_parting_line
                values = [ values 'flatness' ];
            end
            
        end
        
    end
    
    
    properties ( Access = private, Constant )
        
        ANALYSIS_DIMENSION = 3;
        
    end
    
    
    methods ( Access = private )
        
        function parting_line_array = create_parting_line_array( ...
                obj, ...
                rotated_interior, ...
                outer_perimeter, ...
                path ...
                )
            
            path( path == 0 ) = nan;
            parting_line_array = obj.unproject_perimeter( ...
                rotated_interior, ...
                outer_perimeter, ...
                path, ...
                path ...
                );
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function projected_interior = identify_projected_interior( ...
                mesh_interior ...
                )
            
            projected_interior = any( ...
                mesh_interior, ...
                PartingPerimeter.ANALYSIS_DIMENSION ...
                );
            
        end
        
        
        function projected_perimeter = identify_projected_perimeter( ...
                projected_interior ...
                )
            
            projected_perimeter = bwperim( ...
                projected_interior, ...
                conndef( 2, 'minimal' ) ...
                );
            
        end
        
        
        function [ max_slice, min_slice ] = compute_unprojection_bounds( ...
                rotated_interior, ...
                projected_perimeter ...
                )
            
            sz = size( rotated_interior );
            [ ~, ~, Z ] = meshgrid( 1 : sz( 2 ), 1 : sz( 1 ), 1 : sz( 3 ) );
            swept_perimeter = PartingPerimeter.sweep_perimeter( ...
                sz, ...
                projected_perimeter ...
                );
            Z( ~swept_perimeter | ~rotated_interior ) = NaN;
            max_slice = max( Z, [], PartingPerimeter.ANALYSIS_DIMENSION );
            min_slice = min( Z, [], PartingPerimeter.ANALYSIS_DIMENSION );
            
        end
        
        
        function swept_perimeter = sweep_perimeter( sz, projected_perimeter )
            
            swept_perimeter = repmat( projected_perimeter, [ 1 1 sz( 3 ) ] );
            
        end
        
        
        function perimeter = unproject_perimeter( ...
                rotated_interior, ...
                projected_perimeter, ...
                max_slice, ...
                min_slice ...
                )
            
            sz = size( rotated_interior );
            perimeter = zeros( sz );
            for i = 1 : sz( 1 )
                for j = 1 : sz( 2 )
                    if ~projected_perimeter( i, j )
                        continue;
                    end
                    perimeter( i, j, min_slice( i, j ) : max_slice( i, j ) ) = 1;
                end
            end
            
        end
        
        
        function [ jog_free_perimeter, jog_heights_in_voxel_units ] = ...
                compute_jog_free_perimeter( ...
                perimeter, ...
                projected_cc, ...
                min_slice, ...
                max_slice ...
                )
            
            sz = size( perimeter );
            jog_free_perimeter = zeros( sz );
            count = projected_cc.NumObjects;
            jog_heights_in_voxel_units = zeros( count, 1 );
            for i = 1 : count
                
                max_of_min_slice = max( min_slice( projected_cc.PixelIdxList{ i } ) );
                min_of_max_slice = min( max_slice( projected_cc.PixelIdxList{ i } ) );
                jog_height = -( max_of_min_slice - min_of_max_slice - 1 );
                if 0 < jog_height
                    current_perimeter = zeros( projected_cc.ImageSize );
                    current_perimeter( projected_cc.PixelIdxList{ i } ) = 1;
                    sweep = PartingPerimeter.sweep_perimeter( ...
                        sz, ...
                        current_perimeter ...
                        );
                    sweep( :, :, 1 : max_of_min_slice - 1 ) = 0;
                    sweep( :, :, min_of_max_slice + 1 : end ) = 0;
                    jog_free_perimeter = jog_free_perimeter | sweep;
                    jog_heights_in_voxel_units( i ) = jog_height;
                end
                
            end
            
        end
        
        
        function draw = compute_draw( ...
                jog_heights_in_voxel_units, ...
                projected_cc, ...
                min_slice, ...
                max_slice, ...
                scale, ...
                extrema ...
                )
            
            count = projected_cc.NumObjects;
            draws = zeros( count, 1 );
            for i = 1 : count
                
                max_of_min_slice = max( min_slice( projected_cc.PixelIdxList{ i } ) );
                min_of_max_slice = min( max_slice( projected_cc.PixelIdxList{ i } ) );
                draws( i ) = ...
                    ( extrema( 2 ) - ( scale .* min_of_max_slice ) ) ...
                    + ( ( scale .* max_of_min_slice ) - extrema( 1 ) ) ...
                    + ( scale .* ( jog_heights_in_voxel_units( i ) - 1 ) );
                
            end
            draw = max( draws );
            
        end
        
        
        function [ loop_indices, right_side_distances ] = ...
                order_indices_by_loop( outer_perimeter )
            %% Setup
            loop_indices = zeros( 1, sum( outer_perimeter( : ) ) + 1 );
            right_side_distances = zeros( 1, sum( outer_perimeter( : ) ) );
            
            %% Loop Constants
            INVALID_ELEMENT = 0;
            VALID_ELEMENT = 1;
            offsets = generate_neighbor_offsets( outer_perimeter );
            preferred_neighbors = [ 7 8 5 3 2 1 4 6 ];
            neighbor_distances = [ sqrt( 2 ) 1 sqrt( 2 ) 1 1 sqrt( 2) 1 sqrt( 2 ) ];
            
            %% Special Case
            % first iteration is a special case so we end up with a closed loop
            itr = 1;
            loop_indices( itr ) = find( outer_perimeter, 1 );
            itr = itr + 1;
            
            %% Identify Loop Indices
            while true
                
                % get next index
                neighbors = loop_indices( itr - 1 ) + offsets;
                valid_neighbors = outer_perimeter( neighbors ) == VALID_ELEMENT;
                first_available_preference = find( valid_neighbors( preferred_neighbors ), 1 );
                
                % end condition
                if isempty( first_available_preference )
                    % either loop is complete, or isn't a closed loop
                    % because we are marking elements invalid as we pass
                    break;
                end
                
                % updates
                next_index = neighbors( preferred_neighbors( first_available_preference ) );
                loop_indices( itr ) = next_index;
                right_side_distances( itr - 1 ) = neighbor_distances( preferred_neighbors( first_available_preference ) );
                outer_perimeter( next_index ) = INVALID_ELEMENT;
                itr = itr + 1;
                
            end
            
            %% Prepare Output
            assert( loop_indices( 1 ) == loop_indices( end ) );
            loop_indices = loop_indices( 1 : end - 1 );
            
        end
        
    end
    
end

