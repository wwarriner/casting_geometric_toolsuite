classdef (Sealed) ConvectionProperties < handle
    
    % TODO rename "internal interface properties"
    % TODO create interface
    
    methods
        
        function obj = ConvectionProperties( ambient_mesh_id )
            
            obj.ambient_mesh_id = ambient_mesh_id;
            obj.convection = containers.Map( 'keytype', 'double', 'valuetype', 'any' );
            
        end
        
        
        function set_ambient( obj, mesh_id, h )
            
            obj.set( obj.ambient_mesh_id, mesh_id, h );
            
        end
        
        
        function read_ambient( obj, mesh_id, file )
            
            obj.read( obj.ambient_mesh_id, mesh_id, file );
            
        end
        
        
        function set( obj, first_mesh_id, second_mesh_id, h )
            
            assert( first_mesh_id ~= second_mesh_id );
            
            assert( isa( h, 'HProperty' ) );
            
            [ first, second ] = obj.prepare_ids( first_mesh_id, second_mesh_id );
            if ~obj.convection.isKey( first )
                obj.convection( first ) = containers.Map( 'keytype', 'double', 'valuetype', 'any' );
            end
            m = obj.convection( first );
            m( second ) = h; %#ok<NASGU> assigning to a handle is ok
            
        end
        
        
        function read( obj, first_mesh_id, second_mesh_id, file )
            
            data = readtable( file );
            h = HProperty( data.h_t, data.h );
            obj.set( first_mesh_id, second_mesh_id, h );
            
        end
        
        
        function has = has( obj, first_mesh_id, second_mesh_id )
            
            [ first, second ] = obj.prepare_ids( first_mesh_id, second_mesh_id );
            
            has = false;
            if obj.convection.isKey( first )
                m = obj.convection( first );
                if m.isKey( second )
                    has = true;
                end
            end
            
        end
        
        
        function complete = is_ready( obj, expected_mesh_ids )
            
            complete = true;
            count = numel( expected_mesh_ids );
            for i = 1 : count
                for j = i + 1 : count
                    
                    if ~obj.has( expected_mesh_ids( i ), expected_mesh_ids( j ) )
                        complete = false;
                        return;
                    end
                    
                end
            end
            
        end
        
        
        function h = get( obj, first_mesh_id, second_mesh_id )
            
            [ first, second ] = obj.prepare_ids( first_mesh_id, second_mesh_id );
            m = obj.convection( first );
            h = m( second );
            
        end
        
        
        function values = lookup_values( obj, first_mesh_id, second_mesh_id, temperatures )
            
            [ first, second ] = obj.prepare_ids( first_mesh_id, second_mesh_id );
            m = obj.convection( first );
            values = m( second ).lookup_values( temperatures );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        ambient_mesh_id
        convection
        
    end
    
    
    methods ( Access = private, Static )
        
        function [ first, second ] = prepare_ids( first, second )
            
            ids = sort( [ first second ] ) + 1;
            first = ids( 1 );
            second = ids( 2 );
            
        end
        
    end
    
end

