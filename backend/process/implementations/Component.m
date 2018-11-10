classdef (Sealed) Component < Process & matlab.mixin.Copyable
    
    properties ( GetAccess = public, SetAccess = private )
        %% inputs
        stl_path
        
        %% outputs
        path
        name
        
        % rotated
        fv
        normals
        envelope
        draft_angles
        draft_metric
        convex_hull_fv
        
        % invariant
        convex_hull_volume
        triangle_areas
        surface_area
        volume
        hole_count
        flatness
        ranginess
        solidity
        
    end
    
    
    properties ( Access = public, Constant )
        
        NAME = 'component'
        
    end
    
    
    methods ( Access = public )
        
        function obj = Component( varargin )
            
            obj = obj@Process( varargin{ : } );
            
        end
        
        
        function run( obj )
            
            if ~isempty(obj.options)
                obj.stl_path = obj.options.input_stl_path;
                assert( ~isempty( obj.stl_path ) );
            end
            
            obj.printf( 'Preparing component...\n' );
            if ~isempty( obj.stl_path )
                obj.read_from_path( obj.stl_path );
            end
            obj.printf( '\b %s\n', obj.name );
            [ obj.convex_hull_fv, obj.convex_hull_volume ] = ...
                Component.determine_convex_hull( obj.fv.vertices );
            
            obj.printf( '  Computing statistics...\n' );
            obj.triangle_areas = ...
                Component.compute_triangle_areas( obj.fv );
            obj.surface_area = sum( obj.triangle_areas( : ) );
            obj.volume = Component.compute_volume( obj.fv );
            obj.hole_count = Component.count_holes( obj.fv );
            obj.flatness = Component.compute_flatness( ...
                obj.fv.vertices, ...
                obj.convex_hull_fv, ...
                obj.convex_hull_volume ...
                );
            obj.ranginess = Component.compute_ranginess( ...
                obj.surface_area, ...
                obj.volume ...
                );
            obj.solidity = Component.compute_solidity( ...
                obj.volume, ...
                obj.convex_hull_volume ...
                );
            
            obj.update();
            
        end
        
        
        % can construct with ...
        %  - single argument: path to stl file on disk
        %  - two arguments: name of component, and fv of component
        %    - useful for constructing a component from e.g. convex hull
        function legacy_run( obj, varargin )
            
            if nargin == 2
                obj.stl_path = varargin{ 1 };
            elseif nargin == 3
                obj.copy_from_fv( varargin{ 1 }, varargin{ 2 } );
            end
            obj.run();
            
        end
        
        
        function clone = rotate( obj, rotator )
            
            clone = obj.copy();
            clone.fv.vertices = rotator.rotate( clone.fv.vertices );
            clone.normals = rotator.rotate( clone.normals );
            clone.convex_hull_fv.vertices = rotator.rotate( clone.convex_hull_fv.vertices );
            clone.update();
            
        end
        
        
        function fvc = get_draft_fvc( obj )
            
            fvc = obj.fv;
            fvc.facevertexcdata = obj.draft_angles;
            
        end
        
        
        function write( obj, title, common_writer )
            
            if ~common_writer.copy_file( obj.get_full_path() )
                common_writer.write_fv( title, obj.fv );
            end
            common_writer.write_colored_fv( [ title '_draft' ], obj.get_draft_fvc() );
            common_writer.write_table( title, obj.to_table );
            
        end
        
        
        function full_path = get_full_path( obj )
            
            full_path = fullfile( obj.path, [ obj.name '.stl' ] );
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function dependencies = get_dependencies()
            
            dependencies = {};
            
        end
        
    end
    
    
    methods ( Access = protected )
        
        function names = get_table_names( ~ )
            
            names = [ ...
                { 'name' ...
                'surface_area' ...
                'volume' ...
                'hole_count' ...
                'flatness' ...
                'ranginess' ...
                'solidity' } ...
                MeshEnvelope.get_table_row_names() ...
                ];
            
        end
        
        
        function values = get_table_values( obj )
            
            values = [ ...
                { obj.name ...
                obj.surface_area ...
                obj.volume ....
                obj.hole_count ...
                obj.flatness ...
                obj.ranginess ...
                obj.solidity } ...
                obj.envelope.to_table_row() ...
                ];
            
        end
        
    end
    
    
    methods ( Access = private )
        
        function update( obj )
            
            obj.envelope = MeshEnvelope( obj.fv );
            obj.draft_angles = Component.compute_draft_angles( obj.normals );
            obj.draft_metric = obj.compute_draft_metric();
            
        end
        
        
        function read_from_path( obj, stl_path )
            
            obj.stl_path = stl_path;
            [ obj.path, obj.name, ~ ] = fileparts( stl_path );
            obj.printf( '  Reading STL...\n' );
            [ coordinates, obj.normals ] = READ_stl( stl_path );
            [ faces, vertices ] = CONVERT_meshformat( coordinates );
            obj.fv = create_fv( faces, vertices );
            
        end
        
        
        function copy_from_fv( obj, name, fv )
            
            obj.stl_path = '';
            obj.path = '';
            obj.name = name;
            obj.fv = fv;
            obj.normals = compute_normals( obj.fv );
            
        end
        
        
        function draft_metric = compute_draft_metric( obj )
            
            norm_draft_angles = obj.draft_angles ./ ( pi / 2 );
            contribution = norm_draft_angles;
            near_vertical_contribution =  89/90; % one degree from vertical
            contribution( contribution > near_vertical_contribution ) = 1;
            contribution( contribution < 1 ) = interp1( ...
                [ 0 1 ], ...
                [ 0 0.1 ], ...
                contribution( contribution < 1 ) ...
                );
            
            norm_triangles = obj.triangle_areas ./ obj.surface_area;
            
            draft_metric = sum( contribution .* norm_triangles );
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function [ fv, volume ] = determine_convex_hull( vertices )
            
            [ faces, volume ] = convhulln( vertices );
            fv = create_fv( faces, vertices );
            
        end
        
        
        function triangle_areas = compute_triangle_areas( fv )
            
            u = ( fv.vertices( fv.faces( :, 3 ), : ) - fv.vertices( fv.faces( :, 1 ), : ) ).';
            v = ( fv.vertices( fv.faces( :, 3 ), : ) - fv.vertices( fv.faces( :, 2 ), : ) ).';
            sq = vecnorm( u ) .* vecnorm( v );
            sin_theta = sqrt( 1 - ( ( dot( u, v ) ./ sq ) .^ 2 ) );
            triangle_areas = ( ( sq .* sin_theta ) ./ 2 ) .';
            
        end
        
        
        function volume = compute_volume( fv )
            
            volume = compute_fv_volume( fv );
            
        end
        
        
        function draft = compute_draft_angles( normals )
            
            up_vector = repmat( [ 0 0 1 ], [ size( normals, 1 ), 1 ] );
            draft = abs( ...
                pi/2 ...
                - acos( ...
                dot( normals, up_vector, 2 ) ...
                ./ ( vecnorm( normals, 2, 2 ) .* vecnorm( up_vector, 2, 2 ) ) ...
                ) ...
                );
            
        end
        
        
        function hole_count = count_holes( fv )
            
            % Counts holes using euler characteristic Chi
            V = size( fv.vertices, 1 );
            F = size( fv.faces, 1 );
            E = size( determine_edges( fv ), 1 );
            Chi = V - E + F;
            hole_count = ( 2 - Chi ) / 2;
            
        end
        
        
        function flatness = compute_flatness( ...
                vertices, ...
                convex_hull_fv, ...
                convex_hull_volume ...
                )
            
            [ ~, r ] = minboundsphere( vertices, convex_hull_fv.faces );
            bounding_sphere_volume = ( 4 * pi / 3 ) * ( r ^ 3 );
            flatness = 1 - ( convex_hull_volume ./ bounding_sphere_volume );
            
        end
        
        
        function ranginess = compute_ranginess( surface_area, volume )
            
            % coefficient sets raw ranginess of sphere to 0
            % sphere has minimal sa/vol ratio, max is inf, so range is 0 to 1
            COEFF = ( 36 * pi ) ^ ( 1 / 3 );
            nsa = surface_area / ( volume ^ ( 2/3 ) );
            ranginess = 1 - ( COEFF / nsa );
            
        end
        
        
        function solidity = compute_solidity( volume, convex_hull_volume )
            
            solidity = volume ./ convex_hull_volume;
            
        end
        
    end
    
end

