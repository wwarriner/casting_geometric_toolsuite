classdef (Sealed) BasicMold < handle & PrettyAxes3D
    
    methods
        function obj = BasicMold( varargin )
            obj = obj@PrettyAxes3D( varargin{ : } );
        end
        
        function handles = draw( obj, axh )
            state_restorer = obj.hold_if_not_held( axh ); %#ok<NASGU>
            extrema = obj.get_extrema( axh );
            [ min_point, max_point ] = obj.extend_extrema( ...
                extrema, ...
                obj.MOLD_SCALING_FACTOR ...
                );
            handles( 1 ) = obj.plot_box( ...
                axh, ...
                min_point, ...
                max_point, ...
                min_point, ...
                obj.DRAG_COLOR ...
                );
            handles( 2 ) = obj.plot_box( ...
                axh, ...
                min_point, ...
                max_point, ...
                max_point, ...
                obj.COPE_COLOR ...
                );
        end
    end
    
    methods ( Access = private )
        function ph = plot_box( ...
                obj, ...
                axes_handle, ...
                min_point, ...
                max_point, ...
                extreme, ...
                color ...
                )
            origin = obj.get_origin();
            box.vertices = [ ...
                min_point( 1 ) min_point( 2 ) extreme( 3 ); ...
                max_point( 1 ) min_point( 2 ) extreme( 3 ); ...
                max_point( 1 ) max_point( 2 ) extreme( 3 ); ...
                min_point( 1 ) max_point( 2 ) extreme( 3 ); ...
                min_point( 1 ) min_point( 2 ) origin( 3 ); ...
                max_point( 1 ) min_point( 2 ) origin( 3 ); ...
                max_point( 1 ) max_point( 2 ) origin( 3 ); ...
                min_point( 1 ) max_point( 2 ) origin( 3 ); ...
                ];
            box.faces = obj.FACES;
            ph = patch( axes_handle, box );
            ph.FaceColor = color;
            ph.FaceAlpha = 0.1;
            ph.EdgeColor = 'none';
            ph.SpecularStrength = 0.0;
        end
    end
    
    properties ( Access = private, Constant )
        MOLD_SCALING_FACTOR = 1.05;
        DRAG_COLOR = [ 0.0 1.0 0.25 ];
        COPE_COLOR = [ 0.25 1.0 0.0 ];
        FACES = [ ...
                1 2 3 4; ...
                1 2 6 5; ...
                1 4 8 5; ...
                3 2 6 7; ...
                3 4 8 7; ...
                5 6 7 8 ...
                ];
    end
    
end

