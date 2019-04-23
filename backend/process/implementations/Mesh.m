classdef ( Sealed ) Mesh < Process
    
    properties ( GetAccess = public, SetAccess = private )
        % inputs
        component
        desired_element_count
        desired_envelope
        
        % outputs
        element
        scale % mm
        
        interior
        surface
        exterior
        
        origin
        shape
        spacing
        envelope
        
        count
        volume
        
    end
    
    
    methods ( Access = public )
        
        % envelope is optional, if present, will use that envelope instead
        % of component built-in envelope
        function obj = Mesh( varargin )
            
            obj = obj@Process( varargin{ : } );
            
        end
        
        
        function run( obj )
            
            if ~isempty( obj.results )
                obj.component = obj.results.get( Component.NAME );
                % todo: way to get arbitrary envelope in here
                obj.desired_envelope = obj.component.envelope;
            end
            
            if ~isempty( obj.options )
                obj.desired_element_count = obj.options.element_count;
            end
            
            assert( ~isempty( obj.component ) );
            assert( ~isempty( obj.desired_element_count ) );
            assert( ~isempty( obj.desired_envelope ) );
            
            obj.printf( 'Meshing...\n' );
            obj.element = MeshElement( ...
                obj.desired_element_count, ...
                obj.desired_envelope ...
                );
            obj.scale = obj.element.length;
            desired_shape = ceil( ...
                obj.desired_envelope.lengths ...
                ./ obj.element.length ...
                );            
            obj.origin = Mesh.compute_origin( ...
                obj.desired_envelope.min_point, ...
                obj.desired_envelope.lengths, ...
                desired_shape, ...
                obj.scale ...
                );
            
            obj.interior = Mesh.determine_interior( ...
                obj.origin, ...
                desired_shape, ...
                obj.scale, ...
                obj.component.fv ...
                );
            obj.surface = bwperim( obj.interior );
            obj.exterior = ~obj.interior;
            obj.shape = size( obj.interior );
            obj.spacing = repmat( obj.scale, [ 1 3 ] );
            obj.envelope = MeshEnvelope( ...
                obj.origin, ...
                obj.shape .* obj.spacing + obj.origin ...
                );
            obj.count = prod( obj.shape( : ) );
            obj.volume = obj.count .* obj.element.volume;
            
        end
        
        
        function legacy_run( obj, component, desired_element_count, envelope )
            
            if nargin < 4; envelope = component.envelope; end
            
            obj.component = component;
            obj.desired_element_count = desired_element_count;
            obj.desired_envelope = envelope;
            obj.run();
            
        end
        
        
        function fdm_mesh = get_fdm_mesh( obj, padding_in_mm, mold_id, melt_id )
            
            fdm_mesh = double( obj.interior );
            fdm_mesh( obj.interior == 0 ) = mold_id;
            fdm_mesh( obj.interior == 1 ) = melt_id;
            pad_count = round( obj.to_mesh_units( padding_in_mm ) );
            fdm_mesh = padarray( fdm_mesh, pad_count .* ones( 3, 1 ), mold_id, 'both' );
            
        end
        
        
        function element_area = get_element_area( obj )
            
            element_area = obj.element.area;
            
        end
        
        
        function element_volume = get_element_volume( obj )
            
            element_volume = obj.element.volume;
            
        end
        
        
        function position_stl_units = position_from_subs( obj, subs_mesh_units )
            
            position_stl_units = ...
                obj.to_stl_units( subs_mesh_units ) ...
                + obj.origin;
            
        end
        
        
        function subs_mesh_units = subs_from_position( obj, position_stl_units )
            
            subs_mesh_units = ...
                obj.to_mesh_units( position_stl_units - obj.origin );
            
        end
        
        
        function subs_mesh_units = integer_subs_from_position( obj, position_stl_units )
            
            subs_mesh_units = ...
                round( obj.subs_from_position( position_stl_units ) );
            
        end
        
        
        function values_mesh_units = to_mesh_units( obj, values_stl_units )
            
            values_mesh_units = values_stl_units ./ obj.scale;
            
        end
        
        
        function values_mesh_units = to_mesh_area( obj, values_stl_units )
            
            values_mesh_units = values_stl_units ./ obj.get_element_area();
            
        end
        
        
        function values_mesh_units = to_mesh_volume( obj, values_stl_units )
            
            values_mesh_units = values_stl_units ./ obj.get_element_volume();
            
        end
        
        
        % todo change stl to component
        function values_stl_units = to_stl_units( obj, values_mesh_units )
            
            values_stl_units = values_mesh_units .* obj.scale;
            
        end
        
        
        function values_stl_units = to_stl_area( obj, values_mesh_units )
            
            values_stl_units = values_mesh_units .* obj.get_element_area();
            
        end
        
        
        function values_stl_units = to_stl_volume( obj, values_mesh_units )
            
            values_stl_units = values_mesh_units .* obj.get_element_volume();
            
        end
        
        
        function extrema = get_extrema( obj, dimension )
            
            extrema = obj.envelope.get_extrema( dimension );
            
        end
        
        
        function max_length = get_largest_length( obj )
            
            max_length = max( obj.envelope.lengths );
            
        end
        
        
        function cross_section_area = get_cross_section_area( obj, dimension )
            
            relevant_lengths = obj.envelope.lengths;
            relevant_lengths( dimension ) = [];
            cross_section_area = prod( relevant_lengths );
            
        end
        
        
        function write( obj, title, common_writer )
            
            common_writer.write_table( title, obj.to_table );
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function dependencies = get_dependencies()
            
            dependencies = { ...
                Component.NAME ...
                };
            
        end
        
        
        function name = NAME()
            
            name = mfilename( 'class' );
            
        end
        
    end
    
    
    methods ( Access = protected )
        
        function names = get_table_names( ~ )
            
            names = [ ...
                { 'count' } ...
                append_dimension_suffix( 'shape' ) ...
                append_dimension_suffix( 'origin' ) ...
                append_dimension_suffix( 'spacing' ) ...
                MeshEnvelope.get_table_row_names() ...
                MeshElement.get_table_row_names() ...
                ];
            
        end
        
        function values = get_table_values( obj )
            
            values = [ ...
                { obj.count } ...
                num2cell( obj.shape ) ...
                num2cell( obj.origin ) ...
                num2cell( obj.spacing ) ...
                obj.envelope.to_table_row() ...
                obj.element.to_table_row() ...
                ];
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function origin = compute_origin( ...
                component_min_point, ...
                component_lengths, ...
                desired_shape, ...
                scale ...
                )
            
            mesh_lengths = desired_shape .* scale;
            origin_offsets = ( mesh_lengths - component_lengths ) ./ 2;
            center_offset = scale ./ 2;
            origin = component_min_point - origin_offsets + center_offset;
            
        end
        
        
        function interior = determine_interior( ...
                origin, ...
                desired_shape, ...
                scale, ...
                fv ...
                )
            
            points = arrayfun( ...
                @(x,y) x + ( ( 1 : y ) .* scale ), ...
                origin, ...
                desired_shape, ...
                'uniformoutput', 0 ...
                );
            interior = VOXELISE( points{ 1 }, points{ 2 }, points{ 3 }, fv );
            interior = padarray( interior, [ 1 1 1 ], 0, 'both' );
            
        end
        
    end
    
end

