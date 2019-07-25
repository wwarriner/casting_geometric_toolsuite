classdef (Sealed) GeometricProfile < Process
    % GeometricProfile encapsulates the behavior and data of a geometric
    % approach to the solidification profile of castings
    
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
            obj.prepare_edt();
            obj.prepare_filter();
            obj.compute_statistics();
        end
        
        function legacy_run( obj, mesh )
            obj.mesh = mesh;
            obj.run();
        end
        
        function write( obj, title, common_writer )
            scaled_title = [ 'scaled_' title ];
            common_writer.write_array( scaled_title, obj.scaled );
            filtered_title = [ 'filtered_' title ];
            common_writer.write_array( filtered_title, obj.filtered );
            common_writer.write_table( title, obj.to_table() );
        end
        
        function a = to_array( obj )
            a = obj.scaled;
        end
        
        function value = get.unscaled( obj )
            value = obj.mesh.to_mesh_units( obj.scaled );
        end
        
        function value = get.unscaled_interior( obj )
            value = obj.mesh.to_mesh_units( obj.scaled_interior );
        end
        
        function value = get.scaled( obj )
            value = obj.edt.get();
        end
        
        function value = get.scaled_interior( obj )
            value = obj.edt.get( obj.mesh.interior );
        end
        
        function value = get.filtered( obj )
            value = obj.filter.get();
        end
        
        function value = get.filtered_interior( obj )
            value = obj.filter.get( obj.mesh.interior );
        end
        
        function value = get.filter_amount( obj )
            value = obj.compute_filter_amount( obj.mesh.scale );
        end
    end
    
    
    methods ( Access = public, Static )
        
        function name = NAME()
            name = mfilename( 'class' );
        end
        
    end
    
    
    methods ( Access = protected )
        
        function names = get_table_names( ~ )
            names = { ...
                'thickness_ratio' ...
                };
        end
        
        function values = get_table_values( obj )
            values = { ...
                obj.thickness_ratio ...
                };
        end
        
    end
    
    
    properties ( Access = private )
        mesh(1,1) Mesh
        edt EdtProfile
        filter FilteredProfile
    end
    
    
    methods ( Access = private )
        function obtain_inputs( obj )
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
            end
            assert( ~isempty( obj.mesh ) );
        end
        
        function prepare_edt( obj )
            obj.printf( 'Computing EDT profile...\n' );
            obj.edt = EdtProfile( ...
                obj.mesh.surface, ...
                obj.mesh.exterior ...
                );
            obj.edt.scale( obj.mesh.scale );
        end
        
        function prepare_filter( obj )
            obj.printf( 'Filtering profile...\n' );
            obj.filter = FilteredProfile( ...
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
            regional_maxima = imregionalmax( scaled_interior );
            scaled_regional_maxima = scaled_interior( regional_maxima );
            minimum = min( scaled_regional_maxima );
            maximum = max( scaled_regional_maxima );
        end
        
        function threshold = compute_filter_amount( mesh_scale )
            TOLERANCE = 1e-4;
            threshold = mesh_scale * ( 1 + TOLERANCE );
        end
    end
    
end

