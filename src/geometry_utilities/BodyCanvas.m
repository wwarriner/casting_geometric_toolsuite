classdef BodyCanvas < handle
    
    properties ( SetAccess = private, Dependent )
        count(1,1) double
        envelope Envelope
        fv Body
        material_ids(:,1) double
        region_points(:,3) double
        volumes(:,1) double
    end
    
    methods
        function value = get.count( obj )
            value = numel( obj.bodies );
        end
        
        function value = get.envelope( obj )
            value = obj.bodies( 1 ).envelope.copy();
            for i = 2 : numel( obj.bodies )
                body = obj.bodies( 1 );
                value = value.union( body.envelope );
            end
        end
        
        function value = get.fv( obj )
            fv_out = obj.bodies( 1 ).fv;
            for i = 2 : obj.count
                fv_out = merge_fv( fv_out, obj.bodies( i ).fv );
            end
            value = fv_out;
        end
        
        function value = get.material_ids( obj )
            id_list = [ obj.bodies.id ];
            value = nan( max( id_list ), 1 );
            value( id_list ) = id_list;
        end
        
        function value = get.region_points( obj )
            value = nan( obj.count, 3 );
            for i = 1 : obj.count
                value( i, : ) = obj.bodies( i ).fv.vertices( 1, : );
            end
            assert( ~any( isnan( value ), "all" ) );
        end
        
        function value = get.volumes( obj )
            value = obj.bodies.volume;
        end
        
        function add_body( obj, body )
            obj.bodies = [ obj.bodies body ];
        end
    end
    
    properties ( Access = private )
        bodies(:,1) Body
    end
    
end

