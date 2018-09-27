classdef (Sealed) PartingPerimeter < Process
    
    properties ( GetAccess = public, SetAccess = private )
        %% inputs
        mesh
        
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
            
            assert( ~isempty( obj.mesh ) );
            assert( ~isempty( obj.parting_dimension ) );
            
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
            obj.jog_free_perimeter = rotate_from_dimension( ...
                unprojected_jog_free, ...
                inverse ...
                );
            
            obj.printf( '  Computing statistics...\n' );
            
            obj.heights = obj.mesh.to_stl_units( obj.max_slice - obj.min_slice + 1 );
            cc = bwconncomp( obj.projected_perimeter );
            obj.count = cc.NumObjects;
            rp = regionprops( imfill( projected_interior, 'holes' ), 'perimeter' );
            obj.perimeter_length = obj.mesh.to_stl_units( sum( [ rp.Perimeter ] ) );
            obj.length_ratio = obj.perimeter_length ./ largest_length;
            cc = bwconncomp( squeeze( any( obj.jog_free_perimeter, obj.parting_dimension ) ) );
            obj.jog_free_count = cc.NumObjects;
            
        end
        
        
        function name = get_storage_name( obj )
            
            parting_dimension_str = num2str( int64( obj.parting_dimension ), '%d' );
            name = strjoin( { obj.NAME, parting_dimension_str }, '_' );
            
        end
        
        
        function legacy_run( obj, mesh, parting_dimension )
            
            obj.mesh = mesh;
            obj.parting_dimension = parting_dimension;
            obj.run();
            
        end
        
        
        function jog_free_exists = has_jog_free( obj )
            
            jog_free_exists = ( obj.jog_free_count == obj.count );
            
        end
        
        
        function write( obj, title, common_writer )
            
            common_writer.write_array( title, obj.perimeter );
            jog_free_title = [ 'jog_free_' title ];
            common_writer.write_array( jog_free_title, obj.jog_free_perimeter );
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
        
        function names = get_table_names( ~ )
            
            names = { ...
                'draw_ratio', ...
                'length_ratio', ...
                'area_ratio', ...
                'count', ...
                'jog_free_count' ...
                };
            
        end
        
        
        function values = get_table_values( obj )
            
            values = { ...
                obj.draw_ratio, ...
                obj.length_ratio, ...
                obj.area_ratio, ...
                obj.count, ...
                obj.jog_free_count ...
                };
            
        end
        
    end
    
    
    properties ( Access = private, Constant )
        
        ANALYSIS_DIMENSION = 3;
        
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
        
    end
    
end

