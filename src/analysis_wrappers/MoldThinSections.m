classdef (Sealed) MoldThinSections < Process
    % @MoldThinSections identifies regions whose local thickness is below the
    % @threshold property value in the mesh exterior.
    % Settings:
    % - @sweep_coefficient, aggressiveness in determining thin regions, is
    % unitless.
    % - @threshold_casting_length, REQUIRED FINITE, determines what regions
    % count as thin in casting length units.
    % Dependencies:
    % - @Mesh
    % - @GeometricProfile
    
    properties
        sweep_coefficient(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 2 % unitless
        threshold_casting_length(1,1) double {mustBeReal,mustBePositive} = inf;
    end
    
    properties ( SetAccess = private, Dependent )
        count(1,1) double
        label_array(:,:,:) uint32
        volume(1,1) double
    end
    
    methods
        function obj = MoldThinSections( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function legacy_run( obj, mesh, geometric_profile, threshold, sweep_coefficient )
            obj.mesh = mesh;
            obj.geometric_profile = geometric_profile;
            obj.threshold = threshold;
            obj.sweep_coefficient = sweep_coefficient;
            obj.run();
        end
        
        function write( obj, common_writer )
            common_writer.write_array( obj.NAME, obj.to_array(), obj.mesh.spacing, obj.mesh.origin );
            common_writer.write_table( obj.NAME, obj.to_table() );
        end
        
        function a = to_array( obj )
            a = obj.label_array;
        end
        
        function value = get.count( obj )
            value = obj.thin_section_query.count;
        end
        
        function value = get.label_array( obj )
            value = obj.thin_section_query.label_array;
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
            assert( isfinite( obj.threshold_casting_length ) );
        end
        
        function run_impl( obj )
            obj.prepare_thin_section_query();
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
        thin_section_query ThinSectionQuery
    end
    
    methods ( Access = private )
        function prepare_thin_section_query( obj )
            obj.printf( 'Locating mold thin wall sections...\n' );
            amount = [ 1 1 1 ];
            value = 1;
            mask = padarray( obj.mesh.exterior, amount, value, 'both' );
            wall = padarray( -obj.geometric_profile.unscaled, amount, inf, 'both' );
            ts = ThinSectionQuery( ...
                wall, ...
                mask, ...
                obj.mesh.to_mesh_length( obj.threshold_casting_length ), ...
                obj.sweep_coefficient ...
                );
            obj.thin_section_query = ts;
        end
    end
    
end

