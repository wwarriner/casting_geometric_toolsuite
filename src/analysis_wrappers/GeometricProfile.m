classdef (Sealed) GeometricProfile < Process
    % @GeometricProfile encapsulates the behavior and data of a geometric
    % approach to the solidification profile of castings.
    % Settings:
    % - None
    % Dependencies:
    % - @Mesh
    
    properties ( SetAccess = private )
        minimum_thickness(1,1) double {mustBeReal,mustBeFinite}
        maximum_thickness(1,1) double {mustBeReal,mustBeFinite}
        thickness_ratio(1,1) double {mustBeReal,mustBeFinite}
    end
    
    properties ( SetAccess = private, Dependent )
        unscaled(:,:,:) double {mustBeReal,mustBeFinite}
        unscaled_interior(:,:,:) double {mustBeReal,mustBeFinite}
        scaled(:,:,:) double {mustBeReal,mustBeFinite}
        scaled_interior(:,:,:) double {mustBeReal,mustBeFinite}
        filtered(:,:,:) double {mustBeReal,mustBeFinite}
        filtered_interior(:,:,:) double {mustBeReal,mustBeFinite}
        filter_amount(1,1) double {mustBeReal,mustBeFinite}
    end
    
    methods
        function obj = GeometricProfile( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function legacy_run( obj, mesh )
            obj.mesh = mesh;
            obj.run();
        end
        
        function write( obj, common_writer )
            scaled_title = strjoin( [ "scaled" obj.NAME ], "_" );
            common_writer.write_array( scaled_title, obj.scaled, obj.mesh.spacing, obj.mesh.origin );
            filter_title = strjoin( [ "filtered" obj.NAME ], "_" );
            common_writer.write_array( filter_title, obj.filtered, obj.mesh.spacing, obj.mesh.origin );
        end
        
        function a = to_array( obj )
            a = obj.scaled;
        end
        
        function value = get.unscaled( obj )
            value = obj.edt_profile_query.get();
        end
        
        function value = get.unscaled_interior( obj )
            value = obj.edt_profile_query.get( 1.0, obj.mesh.interior );
        end
        
        function value = get.scaled( obj )
            value = obj.edt_profile_query.get( obj.mesh.scale );
        end
        
        function value = get.scaled_interior( obj )
            value = obj.edt_profile_query.get( ...
                obj.mesh.scale, ...
                obj.mesh.interior ...
                );
        end
        
        function value = get.filtered( obj )
            value = obj.filtered_profile_query.get();
        end
        
        function value = get.filtered_interior( obj )
            value = obj.filtered_profile_query.get( obj.mesh.interior );
        end
        
        function value = get.filter_amount( obj )
            value = obj.compute_filter_amount( obj.mesh.scale );
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
            
            assert( ~isempty( obj.mesh ) );
        end
        
        function check_settings( ~ )
            % no settings require checking
        end
        
        function run_impl( obj )
            obj.prepare_edt_profile_query();
            obj.prepare_filtered_profile_query();
            obj.compute_statistics();
        end
        
        function value = to_table_impl( obj )
            value = list2table( ...
                { 'thickness_ratio' }, ...
                { obj.thickness_ratio } ...
                );
        end
    end
    
    properties ( Access = private )
        mesh Mesh
        edt_profile_query EdtProfileQuery
        filtered_profile_query FilteredProfileQuery
    end
    
    methods ( Access = private )
        function prepare_edt_profile_query( obj )
            obj.printf( 'Computing EDT profile...\n' );
            obj.edt_profile_query = EdtProfileQuery( ...
                obj.mesh.surface, ...
                obj.mesh.exterior ...
                );
        end
        
        function prepare_filtered_profile_query( obj )
            obj.printf( '  Filtering profile...\n' );
            obj.filtered_profile_query = FilteredProfileQuery( ...
                obj.scaled, ...
                obj.compute_filter_amount( obj.mesh.scale ) ...
                );
        end
        
        function compute_statistics( obj )
            obj.printf( '  Computing statistics...\n' );
            [ obj.minimum_thickness, obj.maximum_thickness ] = ...
                obj.thickness_analysis( obj.scaled_interior );
            obj.thickness_ratio = ...
                1 - ( obj.minimum_thickness / obj.maximum_thickness );
        end
    end
    
    methods ( Access = private, Static )
        function [ minimum, maximum ] = thickness_analysis( scaled_interior )
            peaks = gray_peaks( scaled_interior );
            minimum = min( peaks );
            maximum = max( peaks );
        end
        
        function threshold = compute_filter_amount( mesh_scale )
            TOLERANCE = 1e-4;
            threshold = mesh_scale * ( 1 + TOLERANCE );
        end
    end
    
end

