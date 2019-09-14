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
        material_ids(:,1) double
        modes(:,1) string
    end
    
    properties ( Constant )
        OVERWRITE = "overwrite";
        ACCUMULATE = "accumulate";
    end
    
    methods
        % To use functionality for 3D, pass only one argument.
        % To use functionality for 1D or 2D, also pass an envelope with 1D 
        % or 2D extent.
        function obj = UniformVoxelCanvas( element_count, envelope )
            if nargin < 2
                envelope = [];
            end
            
            obj.desired_element_count = element_count;
            obj.desired_envelope = envelope;
        end
        
        function add_body( obj, body )
            obj.bodies.add_body( body );
        end
        
        function paint( obj )
            if isempty( obj.desired_envelope )
                envelope_in = obj.bodies.envelope;
            else
                envelope_in = obj.desired_envelope;
            end
            voxels_in = obj.paint_voxels( envelope_in );
            
            obj.envelope = envelope_in;
            obj.voxels = voxels_in;
        end
        
        function value = get.material_ids( obj )
            value = obj.bodies.material_ids;
        end
        
        function value = get.modes( obj )
            value = [ obj.ACCUMULATE obj.OVERWRITE ];
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
        bodies BodyCanvas
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

