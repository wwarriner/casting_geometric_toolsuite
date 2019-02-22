classdef (Sealed) ConvectionProperties < handle
    
    methods
        
        function obj = ConvectionProperties( ambient_mesh_id )
            
            obj.convection = HProperty.empty();
            obj.id_pairs = [];
            obj.ambient_mesh_id = ambient_mesh_id;
            
        end
        
        
        function set_ambient( obj, mesh_id, h )
            
            obj.set( obj.ambient_mesh_id, mesh_id, h );
            
        end
        
        
        function set( obj, first_mesh_id, second_mesh_id, h )
            
            assert( first_mesh_id ~= second_mesh_id );
            
            assert( isa( h, 'HProperty' ) );
            
            obj.add_ids_if_new( first_mesh_id, second_mesh_id );
            ids = obj.prepare_ids( first_mesh_id, second_mesh_id );
            obj.convection( ids( 1 ), ids( 2 ) ) = h;
            
        end
        
        
        function has = has( obj, first_mesh_id, second_mesh_id )
            
            ids = obj.prepare_ids( first_mesh_id, second_mesh_id );
            if isempty( obj.id_pairs )
                has = false;
            else
                has = ismember( ids, obj.id_pairs, 'rows' );
            end
            
        end
        
        
        function complete = is_ready( obj, mesh_ids )
            
            complete = true;
            count = numel( mesh_ids );
            for i = 1 : count
                for j = i + 1 : count
                    
                    if ~obj.has( mesh_ids( i ), mesh_ids( j ) )
                        complete = false;
                        return;
                    end
                    
                end
            end
            
        end
        
        
        function h = get( obj, first_mesh_id, second_mesh_id )
            
            ids = obj.prepare_ids( first_mesh_id, second_mesh_id );
            h = obj.convection( ids( 1 ), ids( 2 ) );
            
        end
        
        
        function extreme = get_extreme( obj )
            
            count = obj.get_id_pair_count();
            extremes = nan( count, 1 );
            for i = 1 : count
                
                ids = obj.get_ids( i );
                extremes( i ) = obj.get( ids( 1 ), ids( 2 ) ).get_extreme();
                
            end
            fn = HProperty.get_extreme_fn();
            extreme = fn( extremes );
            assert( ~isnan( extreme ) );
            
        end
        
        
        function values = lookup_values( obj, first_mesh_id, second_mesh_id, temperatures )
            
            ids = obj.prepare_ids( first_mesh_id, second_mesh_id );
            values = obj.convection( ids( 1 ), ids( 2 ) ).lookup_values( temperatures );
            
        end
        
        
        function convection = nondimensionalize( obj, extreme, temperature_range )
            
            convection = ConvectionProperties( obj.ambient_mesh_id );
            for i = 1 : obj.get_id_pair_count()
                
                ids = obj.get_ids( i );
                h_nd = obj.get( ids( 1 ), ids( 2 ) ).nondimensionalize( extreme, temperature_range );
                convection.set( ids( 1 ), ids( 2 ), h_nd )
                
            end
            
        end
        
    end
    
    
    properties ( Access = private )
        
        convection
        id_pairs
        ambient_mesh_id
        
    end
    
    
    methods ( Access = private )
        
        function add_ids_if_new( obj, first, second )
            
            if ~obj.has( first, second )
                obj.id_pairs( end + 1, : ) = obj.prepare_ids( first, second );
            end
            
        end
        
        
        function ids = get_ids( obj, index )
            
            ids = obj.id_pairs( index, : ) - 1;
            
        end
        
        
        function count = get_id_pair_count( obj )
            
            count = size( obj.id_pairs, 1 );
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function ids = prepare_ids( first, second )
            
            ids = sort( [ first second ] ) + 1;
            
        end
        
    end
    
end

