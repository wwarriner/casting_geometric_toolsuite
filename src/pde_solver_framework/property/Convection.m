classdef Convection < Interface
    
    properties
        ambient_id(1,1) uint32 = 0
    end
    
    methods
        function data = read_ambient( obj, id, file )
            data = obj.read( obj.ambient_id, id, file );
        end
        
        function data = read( obj, first_id, second_id, file )
            data = readtable( file );
            h = HProperty( data.h_t, data.h );
            obj.add( first_id, second_id, h );
        end
        
        function add_ambient( obj, id, h )
            obj.add( obj.ambient_id, id, h );
        end
        
        function add( obj, first_id, second_id, h )
            assert( isa( h, 'HProperty' ) );
            
            add@Interface( obj, first_id, second_id, h );
        end
        
        % @expected_ids is a uint32 vector of ids that exist in the mesh
        function complete = is_ready( obj, expected_ids )
            complete = true;
            count = numel( expected_ids );
            for i = 1 : count
                for j = i + 1 : count
                    if ~obj.has( expected_ids( i ), expected_ids( j ) )
                        complete = false;
                        return;
                    end
                end
            end
        end
    end
    
end

