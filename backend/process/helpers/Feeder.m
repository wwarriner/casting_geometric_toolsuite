classdef (Sealed) Feeder < ProcessHelper & matlab.mixin.Copyable
    
    properties ( GetAccess = public, SetAccess = private )
        
        position
        magnitude
        radius
        diameter
        height
        vertical_offset
        area
        volume
        
        feeder_mesh
        intersection_volume
        exclusive_volume
        interface_area
        accessibility_ratio
        
        fv
        
    end
    
    
    methods ( Access = public )
        
        function obj = Feeder( segment, mesh )
            
            obj.position = segment.centroid;
            obj.magnitude = segment.edt_max;
            [ obj.volume, obj.radius ] = Feeder.feeder_sfsa( segment );
            obj.diameter = 2.0 .* obj.radius;
            obj.vertical_offset = segment.edt_max;
            obj.height = ( 1.5 .* obj.diameter ) + obj.vertical_offset;
            obj.area = pi .* ( obj.radius .^ 2 );
            obj.volume = obj.area .* obj.height;
            obj.update( mesh );
            
        end
        
        
        function clone = rotate( obj, rotator, mesh )
            
            clone = obj.copy();
            clone.position = rotator.rotate( clone.position );
            clone.update( mesh );
            
        end
        
        
        function fv = rotate_fv_only( obj, rotator )
            
            clone = obj.copy();
            clone.position = rotator.rotate( clone.position );
            fv = clone.update_fv_only();
            
        end
        
        
        function tr = to_table_row( obj )
            
            tr = [ ...
                num2cell( obj.position ) ...
                { ...
                obj.radius ...
                obj.diameter ...
                obj.height ...
                obj.vertical_offset ...
                obj.area ...
                obj.volume ...
                obj.intersection_volume ...
                obj.exclusive_volume ...
                obj.interface_area ...
                obj.accessibility_ratio ...
                } ...
                ];
            assert( numel( tr ) == obj.get_table_row_length() );
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function trn = get_table_row_names()
            
            trn = { ...
                'position_x' ...
                'position_y' ...
                'position_z' ...
                'radius' ...
                'diameter' ...
                'height' ...
                'vertical_offset' ...
                'area' ...
                'volume' ...
                'intersection_volume' ...
                'exclusive_volume' ...
                'interface_area' ...
                'accessibility_ratio' ...
                };
            
        end
        
    end
    
    
    methods ( Access = private )
        
        function update( obj, mesh )
            
            obj.fv = Feeder.generate_fv( ...
                obj.position, ...
                obj.radius, ...
                obj.height ...
                );
            
            obj.feeder_mesh = obj.mesh_feeder( mesh );
            obj.intersection_volume = Feeder.compute_intersection_volume( ...
                obj.feeder_mesh, ...
                mesh ...
                );
            obj.exclusive_volume = Feeder.compute_exclusive_volume( ...
                obj.volume, ...
                obj.intersection_volume ...
                );
            obj.interface_area = Feeder.compute_interface_area( ...
                obj.feeder_mesh, ...
                mesh ...
                );
            obj.accessibility_ratio = obj.determine_accessibility( mesh );
            
            %  determine intersect vol
            %  determine exclusive vol
            %  determine interface area
            %  determine accesibility
            
        end
        
        
        function fv = update_fv_only( obj )
            
            fv = Feeder.generate_fv( ...
                obj.position, ...
                obj.radius, ...
                obj.height ...
                );
            
        end
        
        
        function feeder_mesh = mesh_feeder( obj, mesh, min_z_offset )
            
            if nargin < 3
                min_z_offset = 0;
            end
            
            Z_OFFSET = mesh.to_mesh_units( min_z_offset );
            
            sz = size( mesh.interior );
            x = 1 : sz( 1 );
            y = 1 : sz( 2 );
            z = 1 : sz( 3 );
            [ Y, X, Z ] = meshgrid( y, x, z );
            O = mesh.subs_from_position( obj.position );
            X = X - O( 1 );
            Y = Y - O( 2 );
            Z = Z - O( 3 ) - Z_OFFSET;
            R = mesh.to_mesh_units( obj.radius );
            H = mesh.to_mesh_units( obj.height );
            feeder_mesh = zeros( sz );
            feeder_mesh( ...
                ( ( X .^ 2 + Y .^ 2 ) <= R .^ 2 ) ...
                & ( 0 <= Z ) ...
                & ( Z <= H ) ...
                ) ...
                = 1;
            
        end
        
        
        function accessibility_ratio = determine_accessibility( obj, mesh )
            
            % TODO include option for undercuts
            % intersection with undercuts (i.e. cores) should be no-go
            min_z_offset = obj.magnitude;
            accessibility_mesh = obj.mesh_feeder( mesh, min_z_offset );
            intersect = Feeder.compute_intersection_volume( ...
                accessibility_mesh, ...
                mesh ...
                );
            accessibility_ratio = min( max( 1 - ( intersect / obj.volume ), 0 ), 1 );
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function [ volume, radius ] = feeder_sfsa( Segment )
            
            SFSA_VOLUME_COEFFICIENT = 2.51;
            SFSA_VOLUME_POWER = -0.74;
            
            volume = ...
                SFSA_VOLUME_COEFFICIENT ...
                .* Segment.volume ...
                .* ( Segment.shape_factor .^ SFSA_VOLUME_POWER );
            radius = ( volume / ( 3 .* pi ) ) .^ ( 1 / 3 );
            
        end
        
        
        function fv = generate_fv( position, radius, height )
            
            
            % generate
            CYL_RAD_SEGMENTS = 60;
            [ x, y, z ] = cylinder( radius, CYL_RAD_SEGMENTS );
            fv = surf2patch( x, y, z, 'triangles' );
            
            % slim
            vertex_count = size( fv.vertices, 1 );
            fv.faces( fv.faces == vertex_count - 1 ) = 1;
            fv.faces( fv.faces == vertex_count ) = 2;
            fv.vertices( end - 1 : end, : ) = [];
            
            % cap
            fv = Feeder.append_caps( fv );
            
            % transform
            fv.vertices( :, 3 ) = height .* fv.vertices( :, 3 );
            fv.vertices = fv.vertices + position;
            
        end
        
        
        function fv = append_caps( fv )
            
            vertex_count = size( fv.vertices, 1 );
            % lower cap odd, upper cap even
            lower_cap_faces = ...
                Feeder.indices_to_faces( 1 : 2 : vertex_count );
            upper_cap_faces = lower_cap_faces + 1; % change parity
            fv.faces = [ fv.faces; lower_cap_faces; upper_cap_faces ];
            
        end
        
        
        function faces = indices_to_faces( indices )
            
            faces = [ ...
                indices; ...
                circshift( indices, 1 ); ...
                repmat( indices( 1 ), [ 1 length( indices ) ] ) ...
                ];
            faces = faces( :, 2 : end ).';
            
        end
        
        
        function volume = compute_intersection_volume( feeder_mesh, mesh )
            
            volume = mesh.to_stl_volume( sum( ...
                feeder_mesh( : ) ...
                & mesh.interior( : ) ...
                ) );
            
        end
        
        
        function volume = compute_exclusive_volume( ...
                feeder_volume, ...
                intersection_volume ...
                )
            
            volume = feeder_volume - intersection_volume;
            
        end
        
        
        function area = compute_interface_area( feeder_mesh, mesh )
            
            area = mesh.to_stl_area( sum( ...
                feeder_mesh( : ) ...
                & mesh.surface( : ) ...
                ) );
            
        end
        
    end
    
end

