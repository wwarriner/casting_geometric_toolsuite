classdef Convection < handle
    
    properties ( GetAccess = public, SetAccess = private )
        
        convection
        
    end
    
    
    methods
        
        function obj = Convection()
            
            obj.convection = MaterialProperty.empty();
            
        end
        
        
        function add_convection( ...
                obj, ...
                first_material_id, ...
                second_material_id, ...
                material_property ...
                )
            
            ids = sort( [ first_material_id second_material_id ] ) + 1;
            obj.convection( ids( 1 ), ids( 2 ) ) = ...
                material_property;
            
        end
        
        
        function values = lookup( obj, first_material_id, second_material_id, temperatures )
            
            ids = sort( [ first_material_id second_material_id ] ) + 1;
            values = obj.convection( ids( 1 ), ids( 2 ) ).lookup( temperatures );
            
        end
        
    end
    
end

