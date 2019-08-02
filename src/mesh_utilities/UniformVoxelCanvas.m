classdef UniformVoxelCanvas < handle
    
    properties
        default_body_id(1,1) uint32 {mustBeNonnegative} = 1
    end
    
    properties ( SetAccess = private )
        voxels Voxels
    end
    
    properties ( SetAccess = private, Dependent )
        material_ids(:,1) uint32 {mustBeNonnegative}
    end
    
    methods
        function obj = UniformVoxelCanvas( element_count )
            obj.desired_element_count = element_count;
        end
        
        function add_body( obj, body )
            obj.body_list = [ obj.body_list body ];
        end
        
        function paint( obj )
            obj.voxels = obj.paint_voxels(); 
        end
        
        function value = get.material_ids( obj )
            value = obj.get_material_ids();
        end
    end
    
    properties ( Access = private )
        desired_element_count(1,1) double {mustBeNonnegative}
        dimension_count(1,1) uint32 {mustBePositive} = 3
        body_list(:,1) Body
    end
    
    methods ( Access = private )
        function ids = get_material_ids( obj )
            id_list = [ obj.body_list.id ];
            ids = nan( max( id_list ), 1 );
            ids( id_list ) = id_list;
        end
        
        function voxels = paint_voxels( obj )
            envelope = obj.unify_envelopes();
            voxels = Voxels( ...
                obj.desired_element_count, ...
                envelope, ...
                double( obj.default_body_id ) ...
                );
            for i = 1 : numel( obj.body_list )
                b = obj.body_list( i );
                voxels.paint( b.fv, b.id );
            end
            assert( ~any( voxels.values == 0, 'all' ) );
        end
        
        function envelope = unify_envelopes( obj )
            envelope = obj.body_list( 1 ).envelope.copy();
            for i = 2 : numel( obj.body_list )
                body = obj.body_list( 1 );
                envelope = envelope.union( body.envelope );
            end
        end
    end
    
end

