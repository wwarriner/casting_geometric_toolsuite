classdef UniformVoxelCanvas < handle
    
    properties
        default_body_id(1,1) uint32 {mustBeNonnegative} = 1
        mode(1,1) string = UniformVoxelCanvas.OVERWRITE
    end
    
    properties ( SetAccess = private )
        envelope Envelope
        voxels Voxels
    end
    
    properties ( SetAccess = private, Dependent )
        material_ids(:,1) uint32 {mustBeNonnegative}
        modes(:,1) string
    end
    
    properties ( Constant )
        OVERWRITE = "overwrite";
        ACCUMULATE = "accumulate";
    end
    
    methods
        function obj = UniformVoxelCanvas( element_count, envelope )
            if nargin < 2
                envelope = [];
            end
            
            obj.desired_element_count = element_count;
            obj.desired_envelope = envelope;
        end
        
        function add_body( obj, body )
            obj.body_list = [ obj.body_list body ];
        end
        
        function paint( obj )
            if isempty( obj.desired_envelope )
                envelope_in = obj.unify_envelopes();
            else
                envelope_in = obj.desired_envelope;
            end
            voxels_in = obj.paint_voxels( envelope_in );
            
            obj.envelope = envelope_in;
            obj.voxels = voxels_in;
        end
        
        function value = get.material_ids( obj )
            id_list = [ obj.body_list.id ];
            value = nan( max( id_list ), 1 );
            value( id_list ) = id_list;
        end
        
        function value = get.modes( obj )
            value = [ obj.ACCUMULATE obj.OVERWRITE ];
        end
        
        function value = get.envelope( obj )
            value = obj.envelope.copy();
        end
        
        function set.mode( obj, value )
            assert( isstring( value ) );
            assert( ismember( value, obj.modes ) ); %#ok<MCSUP>
            
            obj.mode = value;
        end
    end
    
    properties ( Access = private )
        desired_element_count(1,1) double {mustBeNonnegative}
        desired_envelope % Envelope
        dimension_count(1,1) uint32 {mustBePositive} = 3
        body_list(:,1) Body
    end
    
    methods ( Access = private )
        function voxels = paint_voxels( obj, envelope )
            voxels = Voxels( ...
                obj.desired_element_count, ...
                envelope, ...
                double( obj.default_body_id ) ...
                );
            for i = 1 : numel( obj.body_list )
                b = obj.body_list( i );
                voxels = obj.paint_body( b, voxels );
            end
        end
        
        function envelope = unify_envelopes( obj )
            envelope = obj.body_list( 1 ).envelope.copy();
            for i = 2 : numel( obj.body_list )
                body = obj.body_list( 1 );
                envelope = envelope.union( body.envelope );
            end
        end
        
        function voxels = paint_body( obj, body, voxels )
            switch obj.mode
                case obj.OVERWRITE
                    voxels.paint( body.fv, body.id );
                case obj.ACCUMULATE
                    voxels.add( body.fv, body.id );
                otherwise
                    assert( false );
            end
        end
    end
    
end

