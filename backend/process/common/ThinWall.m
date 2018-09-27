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
        
        % region is: "cavity", "die" or "mold"
        function obj = ThinWall( varargin )
            
            obj = obj@Process( varargin{ : } );
            
        end
        
        
        function run( obj )
            
            if ~isempty(obj.results)
                obj.component = obj.results.get( Component.NAME );
                obj.mesh = obj.results.get( Mesh.NAME );
                obj.profile = obj.results.get( EdtProfile.NAME );
            end
            
            obj.region = obj.DEFAULT_REGION;
            obj.sweep_coefficient = obj.DEFAULT_SWEEP_COEFFICIENT;
            if ~isempty(obj.options)
                if isprop( obj.options, 'thin_wall_region' )
                    obj.region = obj.options.thin_wall_region;
                end
                obj.threshold_in_component_units = obj.select_threshold_from_options( obj.region, obj.options );
                if isprop( obj.options, 'sweep_coefficient' )
                    obj.sweep_coefficient = obj.options.sweep_coefficient;
                end
            end
            
            assert( ~isempty( obj.component ) );
            assert( ~isempty( obj.mesh ) );
            assert( ~isempty( obj.profile ) );
            assert( ~isempty( obj.threshold_in_component_units ) );
            assert( ~isempty( obj.region ) );
            assert( ~isempty( obj.sweep_coefficient ) );
            
            obj.printf( 'Locating thin wall sections...\n' );
            edt = ThinWall.select_edt( obj.profile, obj.region );
            padding = ones( 1, ndims( edt ) );
            border_value = ThinWall.select_border_value( obj.region );
            mask = ThinWall.select_mask( obj.mesh, obj.region );
            mask = padarray( mask, padding, border_value, 'both' );
            
            other_wall = edt > obj.threshold_in_component_units;
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
            
            name = strjoin( { obj.NAME, obj.region }, '_' );
            
        end
        
        
        function set_region( obj, region )
            
            obj.region = region;
            
        end
        
        
        function set_cavity( obj, threshold )
            
            obj.region = obj.CAVITY;
            obj.threshold_in_component_units = threshold;
            
        end
        
        
        function set_mold( obj, threshold )
            
            obj.region = obj.MOLD;
            obj.threshold_in_component_units = threshold;
            
        end
        
        
        function legacy_run( ...
                obj, ...
                component, ...
                mesh, ...
                profile, ...
                threshold_in_component_units, ...
                region, ...
                sweep_coefficient ...
                )
            
            if nargin < 7; sweep_coefficient = 1; end
            obj.component = component;
            obj.mesh = mesh;
            obj.profile = profile;
            obj.threshold_in_component_units = threshold_in_component_units;
            obj.region = region;
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
    
    
    methods ( Access = public, Static )
        
        function dependencies = get_dependencies()
            
            dependencies = { ...
                Component.NAME, ...
                Mesh.NAME, ...
                EdtProfile.NAME ...
                };
            
        end
        
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
    
    
    properties( Access = private, Constant )
        
        CAVITY = "cavity";
        DIE = "die";
        MOLD = "mold";
        
        DEFAULT_SWEEP_COEFFICIENT = 1;
        DEFAULT_THRESHOLD = inf;
        DEFAULT_REGION = 'cavity';
        
    end
    
    
    methods ( Access = private, Static )
        
        function mask = select_mask( Mesh, region )
            
            if strcmpi( region, ThinWall.CAVITY )
                mask = Mesh.interior;
            elseif strcmpi( region, ThinWall.DIE ) || strcmpi( region, ThinWall.MOLD )
                mask = Mesh.exterior;
            else
                error( "incorrect region\n" );
            end
            
        end
        
        
        function edt = select_edt( EdtProfile, region )
            
            edt = EdtProfile.scaled;
            if strcmpi( region, ThinWall.CAVITY )
                % do nothing
            elseif strcmpi( region, ThinWall.DIE ) || strcmpi( region, ThinWall.MOLD )
                edt = -edt;
            else
                error( "incorrect region\n" );
            end
            edt( edt < 0 ) = 0;
            
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
            
            if strcmpi( region, ThinWall.CAVITY )
                threshold = options.thin_wall_cavity_threshold;
            elseif strcmpi( region, ThinWall.DIE ) || strcmpi( region, ThinWall.MOLD )
                threshold = options.thin_wall_mold_threshold;
            else
                error( "incorrect region\n" );
            end
            
        end
        
    end
    
end

