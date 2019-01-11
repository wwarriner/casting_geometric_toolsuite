classdef (Sealed) EdtProfile < Process
    
    properties ( Access = public )
        %% inputs
        mesh
        
        %% outputs
        scaled
        scaled_interior
        filtered
        filtered_interior
        minimum_thickness
        maximum_thickness
        thickness_ratio
        
    end
    
    
    properties ( Access = public, Constant )
        
        NAME = 'solidification_profile'
        
    end
    
    
    methods ( Access = public )
        
        function obj = EdtProfile( varargin )
            
            obj = obj@Process( varargin{ : } );
            
        end
        
        
        function run( obj )
            
            if ~isempty( obj.results )
                obj.mesh = obj.results.get( Mesh.NAME );
                % todo rename to solidification_profile
                % todo make strategy-based
                %  - geometric/edt
                %  - tds solver
                %  - magma, etc, someday??
                % options controls choice of strategy
            end
            
            assert( ~isempty( obj.mesh ) );
            
            obj.printf( 'Computing EDT profile...\n' );
            obj.scaled = obj.mesh.to_stl_units( bwdistsc( obj.mesh.surface ) );
            obj.scaled( obj.mesh.exterior ) = -obj.scaled( obj.mesh.exterior );
            obj.scaled_interior = obj.scaled;
            obj.scaled_interior( obj.mesh.exterior ) = 0;
            [ obj.minimum_thickness, obj.maximum_thickness ] = ...
                EdtProfile.thickness_analysis( obj.scaled_interior );
            obj.thickness_ratio = ...
                1 - ( obj.minimum_thickness / obj.maximum_thickness );
            obj.filtered = EdtProfile.filter( ...
                obj.scaled, ...
                obj.mesh.interior, ...
                obj.mesh.scale ...
                );
            obj.filtered_interior = obj.filtered;
            obj.filtered_interior( obj.mesh.exterior ) = 0;
            
        end
        
        
        function legacy_run( obj, mesh )
            
            obj.mesh = mesh;
            obj.run();
            
        end
        
        
        function write( obj, title, common_writer )
            
            scaled_title = [ 'scaled_' title ];
            common_writer.write_array( scaled_title, obj.scaled_interior );
            filtered_title = [ 'filtered_' title ];
            common_writer.write_array( filtered_title, obj.filtered );
            common_writer.write_table( title, obj.to_table() );
            
        end
        
        
        function a = to_array( obj )
            
            a = obj.scaled_interior;
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function dependencies = get_dependencies()
            
            dependencies = { ...
                Mesh.NAME ...
                };
            
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
    
    
    methods ( Access = private, Static )
        
        function [ minimum, maximum ] = thickness_analysis( scaled_interior )
            
            regional_maxima = imregionalmax( scaled_interior );
            scaled_regional_maxima = scaled_interior( regional_maxima );
            minimum = min( scaled_regional_maxima );
            maximum = max( scaled_regional_maxima );
            
        end
        
        function filtered = filter( scaled, interior, mesh_scale )
            
            filtered = ...
                EdtProfile.filter_masked( scaled, interior, mesh_scale ) ...
                - EdtProfile.filter_masked( -scaled, ~interior, mesh_scale );
            
        end
        
        
        function array = filter_masked( array, mask, mesh_scale )
            
            array( ~mask ) = 0;
            max_value = max( array( : ) );
            array = max_value .* imhmax( ...
                array ./ max_value, ...
                EdtProfile.get_height( max_value, mesh_scale ) ...
                );
            
        end
        
        
        function height = get_height( max_value, mesh_scale )
            
            TOLERANCE = 1e-4;
            height = ( mesh_scale * ( 1 + TOLERANCE ) ) / max_value;
            
        end
        
    end
    
end

