classdef (Sealed) PartingPerimeter < Process
    
    properties ( GetAccess = public, SetAccess = private )
        mesh
        optimize
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
        flatness
        length_ratio
        area_ratio
        draw_ratio
        
        parting_line
    end
    
    
    methods ( Access = public )
        
        function obj = PartingPerimeter( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function run( obj )
            
            assert( ~isempty( obj.parting_dimension ) );
            
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
            end
            assert( ~isempty( obj.mesh ) );
            
            if ~isempty( obj.options )
                FALLBACK_DO_OPTIMIZE = true;
                obj.optimize = obj.options.get( ...
                    'processes.parting_line.optimize', ...
                    FALLBACK_DO_OPTIMIZE ...
                    );
            end
            assert( ~isempty( obj.optimize ) );
            
            projected_interior = any( obj.mesh.interior, 3 );
            
            % PARTING PERIMETER
            obj.printf( ...
                'Locating parting perimeter for axis %d...\n', ...
                obj.parting_dimension ...
                );
            obj.projected_perimeter = analyses.ProjectedPerimeter( projected_interior );
            obj.perimeter = analyses.PartingPerimeter( obj.mesh.interior, obj.projected_perimeter.perimeter );
            
            % JOG FREE PERIMETER
            obj.printf( '  Finding jog-free perimeter...\n' );
            obj.jog_free_perimeter = analyses.JogFreePerimeter( obj.perimeter.count, obj.perimeter.label_matrix, obj.projected_perimeter.label_matrix, obj.perimeter.limits );
            
            % PARTING LINE
            obj.printf( '  Finding optimal parting line...\n' );
            obj.parting_line = analyses.PartingLine( obj.mesh.interior, uint64( obj.projected_perimeter.label_matrix ), obj.perimeter.limits );
            
            % STATISTICS
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
            % TODO expand parting line opt to every connected component of the
            % parting perimeter
            % TODO compute draw using parting line values
            largest_length = obj.mesh.get_largest_length();
            obj.draw_ratio = obj.draw / largest_length;
            obj.length_ratio = obj.perimeter_length ./ largest_length;
            cc = bwconncomp( squeeze( any( obj.jog_free_perimeter, obj.parting_dimension ) ) );
            obj.jog_free_count = cc.NumObjects;
        end
        
        function legacy_run( obj, mesh, parting_dimension, optimize )
            if nargin < 4
                optimize = false;
            end
            obj.mesh = mesh;
            obj.parting_dimension = parting_dimension;
            obj.optimize = optimize;
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
        
        function name = NAME()
            name = mfilename( 'class' );
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
            if obj.optimize
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
            if obj.optimize
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
                    + scale; %...
                %+ ( scale .* ( jog_heights_in_voxel_units( i ) - 1 ) );
            end
            draw = max( draws );
        end
        
    end
    
end

