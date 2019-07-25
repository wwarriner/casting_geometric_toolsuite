classdef (Sealed) MoldThinWall < Process
    
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
        function obj = MoldThinWall( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function run( obj )
            obj.obtain_inputs();
            obj.prepare_thin_sections();
        end
        
        function legacy_run( obj, mesh, profile, threshold, sweep_coefficient )
            obj.mesh = mesh;
            obj.profile = profile;
            obj.threshold = threshold;
            obj.sweep_coefficient = sweep_coefficient;
        end
        
        function write( obj, title, common_writer )
            common_writer.write_array( title, obj.to_array() );
            common_writer.write_table( title, obj.to_table() );
        end
        
        function a = to_array( obj )
            a = obj.label_array;
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
        profile(1,1) GeometricProfile
        thin_sections(1,1) ThinSections
    end
    
    methods ( Access = private )
        function obtain_inputs( obj )
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
                geometric_profile_key = ProcessKey( GeometricProfile.NAME );
                obj.profile = obj.results.get( geometric_profile_key );
            end
            assert( ~isempty( obj.mesh ) );
            assert( ~isempty( obj.profile ) );
            
            if ~isempty( obj.options )
                loc = 'processes.thin_wall.mold_threshold_stl_units';
                obj.threshold = obj.options.get( loc, obj.threshold );
                % have to halve the threshold, because EDT is half of thickness
                obj.threshold = 0.5 .* obj.threshold;
                loc = 'processes.thin_wall.mold_sweep_coefficient';
                obj.sweep_coefficient = obj.options.get( loc, obj.sweep_coefficient );
            end
            assert( ~isempty( obj.threshold ) );
            assert( ~isempty( obj.sweep_coefficient ) );
        end
        
        function prepare_thin_sections( obj )
            obj.printf( 'Locating mold thin wall sections...\n' );
            amount = [ 1 1 1 ];
            value = 1;
            mask = padarray( obj.mesh.exterior, amount, value, 'both' );
            wall = padarray( -obj.profile.unscaled, amount, inf, 'both' );
            ts = ThinSections( ...
                wall, ...
                mask, ...
                obj.mesh.to_mesh_units( obj.threshold ), ...
                obj.sweep_coefficient ...
                );
            obj.thin_sections = ts;
        end
    end
    
end

