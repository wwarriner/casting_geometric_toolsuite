classdef (Sealed) CavityThinSection < Process
    % @CavityThinSection identifies regions whose local thickness is below the
    % @threshold property value.
    % Settings:
    % - @threshold, determines what regions count as thin in component
    % units.
    % - @sweep_coefficient, aggressiveness in determining thin regions, is
    % unitless.
    % Dependencies:
    % - @Mesh
    % - @GeometricProfile
    
    properties
        threshold(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1 % component length units
        sweep_coefficient(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 2 % unitless
    end
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint64
        label_array(:,:,:) uint64
        volume(1,1) double
    end
    
    methods
        function obj = CavityThinSection( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function run( obj )
            obj.obtain_inputs();
            obj.prepare_thin_sections();
        end
        
        function legacy_run( obj, mesh, geometric_profile, threshold, sweep_coefficient )
            obj.mesh = mesh;
            obj.geometric_profile = geometric_profile;
            obj.threshold = threshold;
            obj.sweep_coefficient = sweep_coefficient;
        end
        
        function write( obj, common_writer )
            common_writer.write_array( obj.NAME, obj.to_array() );
            common_writer.write_table( obj.NAME, obj.to_table() );
        end
        
        function value = to_array( obj )
            value = obj.label_array;
        end
        
        function value = to_table( obj )
            value = table( ...
                obj.count, obj.volume, ...
                'variablenames', ...
                { 'count' 'volume' } ...
                );
        end
        
        function value = get.count( obj )
            value = obj.thin_sections.count;
        end
        
        function value = get.label_array( obj )
            value = obj.thin_sections.label_array;
        end
        
        function value = get.volume( obj )
            voxel_count = sum( obj.label_array > 0, 'all' );
            value = obj.mesh.to_mesh_volume( voxel_count );
        end
    end
    
    methods ( Access = public, Static )
        function name = NAME()
            name = mfilename( 'class' );
        end
    end
    
    properties ( Access = private )
        mesh(1,1) Mesh
        geometric_profile(1,1) GeometricProfile
        thin_sections(1,1) ThinSections
    end
    
    methods ( Access = private )
        function obtain_inputs( obj )
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
                geometric_profile_key = ProcessKey( GeometricProfile.NAME );
                obj.geometric_profile = obj.results.get( geometric_profile_key );
            end
            assert( ~isempty( obj.mesh ) );
            assert( ~isempty( obj.geometric_profile ) );
            
            if ~isempty( obj.options )
                loc = 'processes.thin_wall.cavity_threshold_stl_units';
                obj.threshold = obj.options.get( loc, obj.threshold );
                % have to halve the threshold, because EDT is half of thickness
                obj.threshold = 0.5 .* obj.threshold;
                loc = 'processes.thin_wall.cavity_sweep_coefficient';
                obj.sweep_coefficient = obj.options.get( loc, obj.sweep_coefficient );
            end
            assert( ~isempty( obj.threshold ) );
            assert( ~isempty( obj.sweep_coefficient ) );
        end
        
        function prepare_thin_sections( obj )
            obj.printf( 'Locating cavity thin wall sections...\n' );
            amount = [ 1 1 1 ];
            value = 0;
            mask = padarray( obj.mesh.interior, amount, value, 'both' );
            wall = padarray( obj.geometric_profile.unscaled, amount, 0, 'both' );
            ts = ThinSectionQuery( ...
                wall, ...
                mask, ...
                obj.mesh.to_mesh_units( obj.threshold ), ...
                obj.sweep_coefficient ...
                );
            obj.thin_sections = ts;
        end
    end
    
end

