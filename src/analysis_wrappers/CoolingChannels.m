classdef (Sealed) CoolingChannels < Process
    
    % TODO extract Query class(es)
    
    properties
        channel_casting_surface_d_mm(1,1) double {...
            mustBeReal,...
            mustBeFinite,...
            mustBeGreaterThanOrEqual(channel_casting_surface_d_mm,0)...
            }
        channel_other_surface_d_mm(1,1) double {...
            mustBeReal,...
            mustBeFinite,...
            mustBeGreaterThanOrEqual(channel_other_surface_d_mm,0)...
            }
        channel_diameter_mm(1,1) double {...
            mustBeReal,...
            mustBeFinite,...
            mustBeGreaterThanOrEqual(channel_diameter_mm,0)...
            }
    end
    
    properties ( SetAccess = private, Dependent )
        locations(:,:,:) logical
    end
    
    methods
        function obj = CoolingChannels( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function legacy_run( obj, mesh )
            obj.mesh = mesh;
            obj.run();
        end
        
        function write( obj, common_writer )
            common_writer.write_array( obj.NAME, obj.to_array(), obj.mesh.spacing, obj.mesh.origin );
        end
        
        function value = to_array( obj )
            value = obj.values;
        end
        
        function value = get.locations( obj )
            value = obj.values;
        end
    end
    
    methods ( Access = public, Static )
        function name = NAME()
            name = string( mfilename( 'class' ) );
        end
    end
    
    methods ( Access = protected )
        function update_dependencies( obj )
            mesh_key = ProcessKey( Mesh.NAME );
            obj.mesh = obj.results.get( mesh_key );
            
            assert( ~isempty( obj.mesh ) );
        end
        
        function check_settings( obj )
            assert( obj.channel_casting_surface_d_mm > obj.get_radius() )
            assert( obj.channel_other_surface_d_mm > obj.get_radius() )
        end
        
        function run_impl( obj )
            % HACK: flipud to view from Z+
            [ ~, upper ] = max( flip( obj.mesh.surface, 3 ), [], 3 );
            upper = uint32( upper );
            upper = unproject( cat( 3, upper, upper ), obj.mesh.shape( 3 ) );
            upper = flip( upper, 3 );
            upper( :, :, end ) = false;
            upper_edt = EdtProfileQuery( upper, obj.mesh.exterior );
            upper_edt = upper_edt.get( obj.mesh.scale, obj.mesh.interior );
            upper_thresh = obj.channel_casting_surface_d_mm + obj.get_radius();
            upper_edt = upper_edt >= upper_thresh;
            
            other = obj.mesh.surface & ~upper;
            other = padarray( other, [ 1 1 1 ], false, "both" );
            ext = padarray( obj.mesh.exterior, [ 1 1 1 ], true, "both" );
            other_edt = EdtProfileQuery( other, ext );
            int = padarray( obj.mesh.interior, [ 1 1 1 ], false, "both" );
            other_edt = other_edt.get( obj.mesh.scale, int );
            other_thresh = obj.channel_other_surface_d_mm + obj.get_radius();
            other_edt = other_edt >= other_thresh;
            other_edt = other_edt( 2:end-1, 2:end-1, 2:end-1 );
            
            all_edt = upper_edt & other_edt;
            [ ~, upper ] = max( flip( all_edt, 3 ), [], 3 );
            upper = uint32( upper );
            upper = unproject( cat( 3, upper, upper ), obj.mesh.shape( 3 ) );
            upper = flip( upper, 3 );
            d = bwdistgeodesic( obj.mesh.interior, upper, "quasi-euclidean" );
            obj.values = d <= obj.get_radius();
            obj.values = obj.values + upper;
        end
        
        function value = to_table_impl( obj )
            value = table();
        end
    end
    
    properties ( Access = private )
        mesh Mesh
        values(:,:,:) double
    end
    
    methods ( Access = private )
        function radius = get_radius( obj )
            radius = 0.5 * obj.channel_diameter_mm;
        end
    end
    
end

