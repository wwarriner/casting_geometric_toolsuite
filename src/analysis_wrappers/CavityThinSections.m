classdef (Sealed) CavityThinSections < Process
    % @CavityThinSections identifies regions whose local thickness is below the
    % @threshold property value in the mesh interior.
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
        count(1,1) uint32
        label_array(:,:,:) uint32
        volume(1,1) double
    end
    
    methods
        function obj = CavityThinSections( varargin )
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
        
        function value = to_table( obj )
            value = list2table( ...
                { 'count' 'volume' }, ...
                { obj.count, obj.volume } ...
                );
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
    end
    
    properties ( Access = private )
        mesh Mesh
        geometric_profile GeometricProfile
        thin_section_query ThinSectionQuery
    end
    
    methods ( Access = private )
        function prepare_thin_section_query( obj )
            obj.printf( 'Locating cavity thin wall sections...\n' );
            amount = [ 1 1 1 ];
            value = 0;
            mask = padarray( obj.mesh.interior, amount, value, 'both' );
            wall = padarray( obj.geometric_profile.unscaled, amount, 0, 'both' );
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

