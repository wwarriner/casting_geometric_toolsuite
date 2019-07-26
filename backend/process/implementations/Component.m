classdef (Sealed) Component < Process & matlab.mixin.Copyable
    
    properties ( GetAccess = public, SetAccess = private )
        % inputs
        stl_path
        
        % outputs
        path
        name
        
        % affected by rigid transformations
        fv
        normals
        envelope
        draft_angles
        draft_metric
        reduced_draft_metric
        convex_hull_fv
        
        % affected by scaling transformations
        centroid
        convex_hull_volume
        triangle_areas
        surface_area
        volume
        
        % transformation invariant
        hole_count
        flatness
        ranginess
        solidity
        
    end
    
    
    methods ( Access = public )
        
        function obj = Component( varargin )
            
            obj = obj@Process( varargin{ : } );
            
        end
        
        
        function run( obj )
            
            if ~isempty( obj.options )
                obj.stl_path = obj.options.get( 'manager.stl_file' );
                assert( ~isempty( obj.stl_path ) );
            end
            
            obj.printf( 'Preparing component...\n' );
            if ~isempty( obj.stl_path )
                obj.read_from_path( obj.stl_path );
            else
                % must have copied an fv if no path
                assert( ~isempty( obj.fv ) );
            end
            obj.printf( ' %s\n', obj.name );
            [ obj.convex_hull_fv, obj.convex_hull_volume ] = ...
                Component.determine_convex_hull( obj.fv.vertices );
            
            obj.printf( '  Computing statistics...\n' );
            obj.update_scaling_transformation_values();
            obj.update_rigid_transformation_values();
            obj.compute_transformation_invariants();
            
        end
        
        
        % can construct with ...
        %  - single argument: path to stl file on disk
        %  - two arguments: name of component, and fv of component
        %    - useful for constructing a component from e.g. convex hull
        function legacy_run( obj, varargin )
            
            if nargin == 2
                % stl_path
                obj.stl_path = varargin{ 1 };
            elseif nargin == 3
                % name, fv
                obj.copy_from_fv( varargin{ 1 }, varargin{ 2 } );
            else
                assert( false );
            end
            obj.run();
            
        end
        
        
        function clone = rotate( obj, rotator )
            
            clone = obj.copy();
            clone.fv.vertices = rotator.rotate( clone.fv.vertices );
            clone.normals = rotator.rotate( clone.normals );
            clone.convex_hull_fv.vertices = rotator.rotate( clone.convex_hull_fv.vertices );
            clone.update_rigid_transformation_values();
            
        end
        
        
        function clone = scale( obj, factor )
            
            clone = obj.copy();
            clone.fv.vertices = clone.fv.vertices .* factor;
            clone.convex_hull_fv.vertices = clone.convex_hull_fv.vertices .* factor;
            clone.convex_hull_volume = clone.convex_hull_volume .* ( factor .^ 3 );
            clone.surface_area = clone.surface_area .* ( factor .^ 2 );
            clone.update_scaling_transformation_values();
            
        end
        
        
        function fvc = get_draft_fvc( obj )
            
            fvc = obj.fv;
            fvc.facevertexcdata = obj.draft_angles;
            
        end
        
        
        function write( obj, common_writer )
            
            if ~common_writer.copy_file( obj.get_full_path() )
                common_writer.write_fv( obj.NAME, obj.fv );
            end
            common_writer.write_colored_fv( [ obj.NAME,  '_draft' ], obj.get_draft_fvc() );
            common_writer.write_table( obj.NAME, obj.to_table );
            
        end
        
        
        function full_path = get_full_path( obj )
            
            full_path = fullfile( obj.path, [ obj.name '.stl' ] );
            
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
        
        function update_rigid_transformation_values( obj )
            
            obj.draft_angles = compute_draft_angles( obj.normals );
            obj.draft_metric = obj.compute_draft_metric();
            obj.reduced_draft_metric = obj.compute_reduced_draft_metric( obj.draft_metric );
            obj.update_all_transformation_values();
            
        end
        
        
        function update_scaling_transformation_values( obj )
            
            obj.triangle_areas = compute_triangle_areas( obj.fv );
            obj.surface_area = sum( obj.triangle_areas( : ) );
            [ obj.volume, obj.centroid ] = compute_fv_volume( obj.fv );
            obj.update_all_transformation_values();
            
        end
        
        
        function update_all_transformation_values( obj )
            
            obj.envelope = MeshEnvelope( obj.fv );
            
        end
        
        function compute_transformation_invariants( obj )
            
            obj.hole_count = count_holes( obj.fv );
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
            
        end
        
        
        function draft_metric = compute_draft_metric( obj )
            
            normalized_draft_angles = obj.draft_angles ./ ( pi / 2 );
%             contribution = norm_draft_angles;
            NEAR_VERTICAL = 89/90; % one degree from vertical
            contribution = zeros( size( normalized_draft_angles ) );
            contribution( normalized_draft_angles >= NEAR_VERTICAL ) = 1;
            contribution( normalized_draft_angles <= NEAR_VERTICAL ) = 0;
%             contribution( contribution < 1 ) = interp1( ...
%                 [ 0 1 ], ...
%                 [ 0 0.1 ], ...
%                 contribution( contribution < 1 ) ...
%                 );            
            normalized_triangle_areas = obj.triangle_areas ./ obj.surface_area;            
            draft_metric = sum( contribution .* normalized_triangle_areas );
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        
        function reduced_draft_metric = compute_reduced_draft_metric( draft_metric )
            
            reduced_draft_metric = draft_metric;
            reduced_draft_metric( draft_metric > 0 ) = ...
                1 ./ ( -log10( reduced_draft_metric( draft_metric > 0 ) ) );
            
        end
        
    end
    
end

