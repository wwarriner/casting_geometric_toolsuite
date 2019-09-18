classdef (Sealed) CavityThickSections < Process
    % @CavityThickSections identifies regions whose local thickness is above
    % some statistically-determined threshold. The intent is to identify regions
    % which are significantly thicker than the intended thickness in a die
    % casting. In an ideal die casting, all sections have the same local
    % thickness to minimize distortion and shrinkage.
    % Settings:
    % - @strategy, scalar string denoting the statistical strategy to use when
    % determining thick sections.
    % - @sweep_coefficient, real, finite, positive scalar double which 
    % controls aggressiveness in determining thick sections, is unitless.
    % - @threshold_casting_length, REQUIRED FINITE, real, positive scalar double
    % which determines what regions count as thick in casting length units.
    % Dependencies:
    % - @Mesh
    % - @GeometricProfile
    % MATLAB Requirements:
    % - Image Processing Toolbox
    % - Statistics and Machine Learning Toolbox
    
    properties
        strategy(1,1) string = "lognormal"
        quantile(1,1) double {...
            mustBeReal,...
            mustBeFinite,...
            mustBeGreaterThanOrEqual(quantile,0),...
            mustBeLessThanOrEqual(quantile,1)...
            } = 0.25
        sweep_coefficient(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 2.0 % unitless
        threshold_casting_length(1,1) double {mustBeReal,mustBePositive} = inf;
    end
    
    properties ( SetAccess = private, Dependent )
        count(1,1) double
        label_array(:,:,:) uint32
        thick_threshold(1,1) double
        volume(1,1) double
    end
    
    methods
        function obj = CavityThickSections( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function legacy_run( obj, mesh, geometric_profile )
            obj.mesh = mesh;
            obj.geometric_profile = geometric_profile;
            obj.run();
        end
        
        function write( obj, common_writer )
            common_writer.write_array( obj.NAME, obj.to_array(), obj.mesh.spacing, obj.mesh.origin );
            common_writer.write_table( obj.NAME, obj.to_table() );
        end
        
        function value = to_array( obj )
            value = obj.label_array;
        end
        
        function value = get.count( obj )
            value = obj.thick_section_query.count;
        end
        
        function value = get.label_array( obj )
            value = obj.thick_section_query.label_array;
        end
        
        function value = get.thick_threshold( obj )
            value = obj.mesh.to_casting_length( obj.thick_section_query.thick_threshold );
        end
        
        function value = get.volume( obj )
            voxel_count = sum( obj.label_array > 0, 'all' );
            value = obj.mesh.to_mesh_volume( voxel_count );
        end
    end
    
    methods ( Access = public, Static )
        function name = NAME()
            name = string( mfilename( 'class' ) );
        end
    end
    
    methods ( Access = protected )
        function update_dependencies( obj )
            mesh_key = ProcessKey( Mesh.NAME );
            obj.mesh = obj.results.get( mesh_key );
            
            geometric_profile_key = ProcessKey( GeometricProfile.NAME );
            obj.geometric_profile = obj.results.get( geometric_profile_key );
            
            assert( ~isempty( obj.mesh ) );
            assert( ~isempty( obj.geometric_profile ) );
        end
        
        function check_settings( obj )
            assert( ismember( obj.strategy, obj.STRATEGY ) );
            assert( isfinite( obj.threshold_casting_length ) );
        end
        
        function run_impl( obj )
            obj.prepare_thick_section_query();
        end
        
        function value = to_table_impl( obj )
            value = list2table( ...
                { 'count' 'volume' }, ...
                { obj.count, obj.volume } ...
                );
        end
    end
    
    properties ( Access = private )
        mesh Mesh
        geometric_profile GeometricProfile
        thick_section_query ThickSectionQuery
    end
    
    methods ( Access = private )
        function prepare_thick_section_query( obj )
            obj.printf( 'Locating cavity thick wall sections...\n' );
            amount = [ 1 1 1 ];
            value = 0;
            mask = padarray( obj.mesh.interior, amount, value, 'both' );
            wall = padarray( obj.geometric_profile.unscaled, amount, 0, 'both' );
            ts = ThickSectionQuery( ...
                wall, ...
                mask, ...
                obj.get_strategy_fn( obj.strategy ), ...
                obj.mesh.to_mesh_length( obj.threshold_casting_length ), ...
                obj.sweep_coefficient ...
                );
            obj.thick_section_query = ts;
        end
        
        function strategy_fn = get_strategy_fn( obj, strategy )
            switch strategy
                case "lognormal"
                    strategy_fn = @(x)CavityThickSections.compute_lognormal(x,obj.quantile);
                case "strict"
                    strategy_fn = @CavityThickSections.compute_strict;
                case "median"
                    strategy_fn = @CavityThickSections.compute_median;
                otherwise
                    assert( false );
            end
        end
    end
    
    properties ( Access = private, Constant )
        STRATEGY = [ "lognormal" "strict" "median" ];
    end
    
    methods ( Access = private, Static )
        
        function value = compute_lognormal( data, percentile )
            if isempty( data ); value = 0; return; end
            data = data( data > 0 );
            parameters = lognfit( data );
            value = logninv( percentile, parameters( 1 ), parameters( 2 ) );
        end
        
        function value = compute_strict( data )
            if isempty( data ); value = 0; return; end
            u = unique( data );
            if length( u ) > 1
                start_edges = ( u( 1 : end - 1 ) + u( 2 : end ) ) ./ 2;
                start_edges = [ ...
                    2 * u( 1 ) - start_edges( 1 ); ...
                    start_edges;
                    2 * u( end ) - start_edges( end ) ...
                    ];
            else
                start_edges = [ 0 u + 1 ];
            end
            
            [ counts, edges ] = histcounts( data, start_edges );
            [ ~, peak_locations ] = findpeaks( [ 0 counts 0 ] );
            peak_edges = edges( peak_locations );
            if length( peak_locations ) == 1
                value = peak_edges;
            else
                value = ( peak_edges( 1 ) + peak_edges( 2 ) ) ./ 2;
            end
        end
        
        function value = compute_median( data )
            if isempty( data ); value = 0; return; end
            value = median( data );
        end
    end
    
end

