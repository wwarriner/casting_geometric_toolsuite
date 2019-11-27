classdef SolidificationInterfaceProperties < InterfacePropertiesBase
    
    properties
        ambient_id(1,1) uint32 = 0
    end
    
    methods
        function data = add_ambient_from_file( obj, id, file )
            data = obj.add_from_file( obj.ambient_id, id, file );
        end
        
        function data = add_from_file( obj, first_id, second_id, file )
            data = readtable( file );
            h = HProperty( data.h_t, data.h );
            obj.add( first_id, second_id, h );
        end
        
        function add_ambient( obj, id, h )
            obj.add( obj.ambient_id, id, h );
        end
        
        function add( obj, first_id, second_id, h )
            assert( isa( h, 'HProperty' ) );
            
            add@InterfacePropertiesBase( obj, first_id, second_id, h );
        end
        
        function v = lookup_ambient( obj, id, varargin )
            v = obj.lookup( obj.ambient_id, id, varargin{ : } );
        end
        
        function v = reduce_ambient( obj, id, fn )
            v = obj.reduce( obj.ambient, id, fn );
        end
    end
    
end

