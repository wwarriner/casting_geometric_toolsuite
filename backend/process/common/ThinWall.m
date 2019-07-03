classdef ThinWall < Process
    
    % NOTE: prefer to use the subclasses instead
    
    properties ( GetAccess = public, SetAccess = private )
        %% inputs
        component
        mesh
        profile
        threshold_in_component_units
        region
        sweep_coefficient
        
        %% outputs
        thin_wall
        volume
        ratio
        
    end
    
    
    methods ( Access = public )
        
        function obj = ThinWall( varargin )
            
            obj = obj@Process( varargin{ : } );
            
        end
        
        
        function run( obj )
            
            assert( ~isempty( obj.region ) );
            
            if ~isempty( obj.results )
                component_key = ProcessKey( Component.NAME );
                obj.component = obj.results.get( component_key );
                
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
                
                geometric_profile_key = ProcessKey( GeometricProfile.NAME );
                obj.profile = obj.results.get( geometric_profile_key );
            end
            assert( ~isempty( obj.component ) );
            assert( ~isempty( obj.mesh ) );
            assert( ~isempty( obj.profile ) );
            
            if ~isempty( obj.options )
                % have to halve the threshold, because EDT is half of thickness
                obj.threshold_in_component_units = 0.5 * ...
                    obj.select_threshold_from_options( obj.region, obj.options );
                obj.sweep_coefficient = obj.select_sweep_coefficient_from_options( obj.region, obj.options );
            end
            assert( ~isempty( obj.threshold_in_component_units ) );
            assert( ~isempty( obj.sweep_coefficient ) );
            
            obj.printf( 'Locating thin wall sections...\n' );
            profile = ThinWall.select_profile( obj.profile, obj.region );
            padding = ones( 1, ndims( profile ) );
            border_value = ThinWall.select_border_value( obj.region );
            mask = ThinWall.select_mask( obj.mesh, obj.region );
            mask = padarray( mask, padding, border_value, 'both' );
            
            other_wall = profile > obj.threshold_in_component_units;
            other_wall = padarray( other_wall, padding, border_value, 'both' );
            
            obj.printf( '  Forward sweep...\n' );
            sweep_distance_in_mesh_units = obj.sweep_coefficient ...
                .* obj.mesh.to_mesh_units( obj.threshold_in_component_units );
            sweep = distance_sweep( ...
                mask, ...
                other_wall, ...
                sweep_distance_in_mesh_units ...
                );
            
            obj.printf( '  Backward sweep...\n' );
            sweep = distance_sweep( ...
                mask, ...
                ~sweep & mask, ...
                sweep_distance_in_mesh_units ...
                );
            
            obj.thin_wall = sweep & mask;
            obj.thin_wall = obj.thin_wall( 2 : end - 1, 2 : end - 1, 2 : end - 1 );
            
            obj.volume = obj.mesh.to_stl_volume( sum( obj.thin_wall( : ) ) );
            obj.ratio = obj.volume ./ obj.component.volume;
            
        end
        
        
        function name = get_storage_name( obj )
            
            name = get_storage_name@Process( obj );
            
        end
        
        
        function set_region( obj, region )
            
            obj.region = region;
            
        end
        
        
        function legacy_run( ...
                obj, ...
                component, ...
                mesh, ...
                profile, ...
                threshold_in_component_units, ...
                sweep_coefficient ...
                )
            
            if nargin < 7; sweep_coefficient = 1; end
            obj.component = component;
            obj.mesh = mesh;
            obj.profile = profile;
            obj.threshold_in_component_units = threshold_in_component_units;
            obj.sweep_coefficient = sweep_coefficient;
            obj.run();
            
        end
        
        
        function write( obj, title, common_writer )
            
            common_writer.write_array( title, obj.to_array() );
            common_writer.write_table( title, obj.to_table() );
            
        end
        
        
        function a = to_array( obj )
            
            a = obj.thin_wall;
            
        end
        
    end
    
    
    properties( Access = protected, Constant )
        
        CAVITY = "cavity";
        DIE = "die";
        MOLD = "mold";
        
    end
    
    
    methods ( Access = protected )
        
        function names = get_table_names( ~ )
            
            names = { ...
                'volume', ...
                'ratio' ...
                };
            
        end
        
        
        function values = get_table_values( obj )
            
            values = { ...
                obj.volume, ...
                obj.ratio ...
                };
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function mask = select_mask( Mesh, region )
            
            if strcmpi( region, ThinWall.CAVITY )
                mask = Mesh.interior;
            elseif strcmpi( region, ThinWall.DIE ) || strcmpi( region, ThinWall.MOLD )
                mask = Mesh.exterior;
            else
                assert( false );
            end
            
        end
        
        
        function profile = select_profile( profile, region )
            
            profile = profile.scaled;
            if strcmpi( region, ThinWall.CAVITY )
                % do nothing
            elseif strcmpi( region, ThinWall.DIE ) || strcmpi( region, ThinWall.MOLD )
                profile = -profile;
            else
                assert( false );
            end
            profile( profile < 0 ) = 0;
            
        end
        
        
        function border_value = select_border_value( region )
            
            if strcmpi( region, ThinWall.CAVITY )
                border_value = 0;
            elseif strcmpi( region, ThinWall.DIE ) || strcmpi( region, ThinWall.MOLD )
                border_value = 1;
            else
                error( "incorrect region\n" );
            end
            
        end
        
        
        function threshold = select_threshold_from_options( region, options )
            
            FALLBACK_VALUE = 1; % mm
            base = 'processes.thin_wall';
            if strcmpi( region, ThinWall.CAVITY )
                threshold = options.get( [ base '.cavity_threshold_stl_units' ], FALLBACK_VALUE );
            elseif strcmpi( region, ThinWall.DIE ) || strcmpi( region, ThinWall.MOLD )
                threshold = options.get( [ base '.mold_threshold_stl_units' ], FALLBACK_VALUE );
            else
                error( "incorrect region\n" );
            end
            
        end
        
        
        function threshold = select_sweep_coefficient_from_options( region, options )
            
            FALLBACK_VALUE = 2;
            base = 'processes.thin_wall';
            if strcmpi( region, ThinWall.CAVITY )
                threshold = options.get( [ base '.cavity_sweep_coefficient' ], FALLBACK_VALUE );
            elseif strcmpi( region, ThinWall.DIE ) || strcmpi( region, ThinWall.MOLD )
                threshold = options.get( [ base '.mold_sweep_coefficient' ], FALLBACK_VALUE );
            else
                error( "incorrect region\n" );
            end
            
        end
        
        
    end
    
end

