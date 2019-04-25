classdef Waterfall < Process
    
    properties ( GetAccess = public, SetAccess = private )
        %% inputs
        mesh
        parting_perimeter
        
        %% outputs
        local_drop
        worst_drop
        gating_opportunity
        
    end
    
    
    methods ( Access = public )
        
        % gravity_direction must be "up" or "down"
        function obj = Waterfall( varargin )
            
            obj = obj@Process( varargin{ : } );
            
        end
        
        
        function run( obj )
            
            assert( ~isempty( obj.parting_dimension ) );
            assert( ~isempty( obj.gravity_direction ) );
            
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
            end
            assert( ~isempty( obj.mesh ) );
            
            if isempty( obj.parting_perimeter )
                parting_perimeter_key = ProcessKey( ...
                    PartingPerimeter.NAME, ...
                    obj.parting_dimension ...
                    );
                obj.parting_perimeter = obj.results.get( parting_perimeter_key );
            end
            assert( ~isempty( obj.parting_perimeter ) );
            
            obj.printf( ...
                'Identifying waterfalls for axis %d and gravity %s...\n', ...
                obj.parting_dimension, ...
                obj.gravity_direction ...
                );
                 
            [ interior, inverse ] = Waterfall.preprocess( ...
                obj.mesh.interior, ...
                obj.parting_dimension, ...
                obj.gravity_direction ...
                );
            exterior = Waterfall.preprocess( ...
                obj.mesh.exterior, ...
                obj.parting_dimension, ...
                obj.gravity_direction ...
                );
            
            sz = size( interior );
            slice_sz = size( interior( :, :, 1 ) );
            local_drop_height = zeros( sz );
            worst_drop_height = zeros( sz );
            for i = 2 : sz( Waterfall.ANALYSIS_DIMENSION ) - 1
                
                % compute current local drop
                prev_drop = local_drop_height( :, :, i - 1 );
                curr_drop = prev_drop + obj.mesh.to_stl_units( 1 );
                curr_drop( exterior( :, :, i ) ) = 0;
                local_drop_height( :, :, i ) = curr_drop;
                
                % compute current worst drop
                curr_interior = interior( :, :, i );
                prev_worst_drop = worst_drop_height( :, :, i - 1 );
                
                prev_interior = interior( :, :, i - 1 );
                prev_slice_inds = find( prev_interior );
                if ~isempty( prev_slice_inds )
                    prev_slice_subs = ind2sub_vec( slice_sz, prev_slice_inds );
                    
                    curr_slice_inds = setdiff( find( curr_interior ), prev_slice_inds );
                    curr_slice_subs = ind2sub_vec( slice_sz, curr_slice_inds );
                    curr_sub_count = length( curr_slice_inds );
                    min_inds = zeros( curr_sub_count, 1 );
                    for j = 1 : curr_sub_count
                        
                        [ ~, min_inds( j ) ] = min( sum( ( prev_slice_subs - curr_slice_subs( j, : ) ) .^ 2, 2 ) );
                        
                    end
                    prev_worst_drop( curr_slice_inds ) = prev_worst_drop( prev_slice_inds( min_inds ) );
                    
                end
                worst_drop_height( :, :, i ) =  max( prev_worst_drop, curr_drop );
                
            end
            worst_drop_height( exterior ) = 0;
            
            obj.local_drop = Waterfall.postprocess( local_drop_height, inverse, obj.gravity_direction );
            obj.worst_drop = Waterfall.postprocess( worst_drop_height, inverse, obj.gravity_direction );
            
            perim = bwperim( obj.mesh.interior ) & obj.parting_perimeter.perimeter;
            values = obj.worst_drop( perim );
            obj.gating_opportunity = obj.mesh.to_stl_units( sum( 1 ./ values ) );
            
        end
        
        
        function legacy_run( obj, mesh, parting_perimeter, gravity_direction )
            
            obj.mesh = mesh;
            obj.parting_perimeter = parting_perimeter;
            obj.parting_dimension = obj.parting_perimeter.parting_dimension;
            obj.gravity_direction = gravity_direction;
            obj.run();
            
        end
        
        
        function write( obj, title, common_writer )
            
            common_writer.write_array( [ title '_local_drop' ], obj.local_drop );
            common_writer.write_array( [ title '_worst_drop' ], obj.worst_drop );
            common_writer.write_table( title, obj.to_table() );
            
        end
        
        
        function a = to_array( obj )
            
            a = obj.worst_drop;
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function name = NAME()
            
            name = mfilename( 'class' );
            
        end
        
        
        function orientation_dependent = is_orientation_dependent()
            
            orientation_dependent = true;
            
        end
        
        
        function gravity_direction = has_gravity_direction()
            
            gravity_direction = true;
            
        end
        
    end
    
    
    methods ( Access = protected )
        
        function names = get_table_names( ~ )
            
            names = { ...
                'gating_opportunity' ...
                };
            
        end
        
        
        function values = get_table_values( obj )
            
            values = { ...
                obj.gating_opportunity ...
                };
            
        end
        
    end
    
    
    properties ( Access = private, Constant )
        
        ANALYSIS_DIMENSION = 3
        
    end
    
    
    methods ( Access = private, Static )
        
        function [ array, inverse ] = preprocess( ...
                array, ...
                parting_dimension, ...
                gravity_direction ...
                )
            
            [ array, inverse ] = rotate_to_dimension( ...
                parting_dimension, ...
                array, ...
                Waterfall.ANALYSIS_DIMENSION ...
                );
            
            if strcmpi( gravity_direction, 'up' )
                array = flip( array, Waterfall.ANALYSIS_DIMENSION );
            elseif strcmpi( gravity_direction, 'down' )
                % do nothing
            else
                error( 'Invalid up direction\n' );
            end
            
        end
        
        
        function array = postprocess( array, inverse, gravity_direction )
            
            if strcmpi( gravity_direction, 'up' )
                array = flip( array, Waterfall.ANALYSIS_DIMENSION );
            elseif strcmpi( gravity_direction, 'down' )
                % do nothing
            else
                error( 'Invalid gravity direction\n' );
            end
            
            array = rotate_from_dimension( array, inverse );
            
        end
        
    end
    
end

