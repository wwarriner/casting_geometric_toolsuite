classdef (Sealed) GeometricProfile < Process
    % @GeometricProfile encapsulates the behavior and data of a geometric
    % approach to the solidification profile of castings.
    % Dependencies:
    % - @Mesh
    
    properties ( SetAccess = private )
        scaled(:,:,:) double
        minimum_thickness(1,1) double
        maximum_thickness(1,1) double
        thickness_ratio(1,1) double
    end
    
    properties ( SetAccess = private, Dependent )
        unscaled(:,:,:) double
        unscaled_interior(:,:,:) double
        scaled_interior(:,:,:) double
        filtered(:,:,:) double
        filtered_interior(:,:,:) double
        filter_amount(1,1) double
    end
    
    methods
        function obj = GeometricProfile( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function run( obj )
            obj.obtain_inputs();
            obj.prepare_edt_profile_query();
            obj.prepare_filter_profile_query();
            obj.compute_statistics();
        end
        
        function legacy_run( obj, mesh )
            obj.mesh = mesh;
            obj.run();
        end
        
        function write( obj, common_writer )
            scaled_title = [ 'scaled_' obj.NAME ];
            common_writer.write_array( scaled_title, obj.scaled, obj.mesh.spacing, obj.mesh.origin );
            filter_title = [ 'filtered_' obj.NAME ];
            common_writer.write_array( filter_title, obj.filtered, obj.mesh.spacing, obj.mesh.origin );
        end
        
        function a = to_array( obj )
            a = obj.scaled;
        end
        
        function value = to_table( obj )
            value = list2table( ...
                { 'thickness_ratio' }, ...
                { obj.thickness_ratio } ...
                );
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
            value = obj.filter_profile_query.get();
        end
        
        function value = get.filtered_interior( obj )
            value = obj.filter_profile_query.get( obj.mesh.interior );
        end
        
        function value = get.filter_amount( obj )
            value = obj.compute_filter_profile_query_amount( obj.mesh.scale );
        end
    end
    
    methods ( Access = public, Static )
        function name = NAME()
            name = string( mfilename( 'class' ) );
        end
    end
    
    properties ( Access = private )
        mesh Mesh
        edt_profile_query EdtProfileQuery
        filter_profile_query FilteredProfileQuery
    end
    
    methods ( Access = private )
        function obtain_inputs( obj )
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
            end
            assert( ~isempty( obj.mesh ) );
        end
        
        function prepare_edt_profile_query( obj )
            obj.printf( 'Computing EDT profile...\n' );
            obj.edt_profile_query = EdtProfileQuery( ...
                obj.mesh.surface, ...
                obj.mesh.exterior ...
                );
        end
        
        function prepare_filter_profile_query( obj )
            obj.printf( 'Filtering profile...\n' );
            obj.filter_profile_query = FilteredProfileQuery( ...
                obj.scaled, ...
                obj.compute_filter_profile_query_amount( obj.mesh.scale ) ...
                );
        end
        
        function compute_statistics( obj )
            obj.printf( 'Computing statistics...\n' );
            [ obj.minimum_thickness, obj.maximum_thickness ] = ...
                obj.thickness_analysis( obj.scaled_interior );
            obj.thickness_ratio = ...
                1 - ( obj.minimum_thickness / obj.maximum_thickness );
        end
    end
    
    methods ( Access = private, Static )
        function [ minimum, maximum ] = thickness_analysis( scaled_interior )
            regional_maxima = imregionalmax( scaled_interior );
            scaled_regional_maxima = scaled_interior( regional_maxima );
            minimum = min( scaled_regional_maxima );
            maximum = max( scaled_regional_maxima );
        end
        
        function threshold = compute_filter_profile_query_amount( mesh_scale )
            TOLERANCE = 1e-4;
            threshold = mesh_scale * ( 1 + TOLERANCE );
        end
    end
    
end

