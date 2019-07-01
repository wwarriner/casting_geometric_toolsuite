classdef (Abstract) MeshInterface < handle
    
    methods ( Access = public )
        
        add_component( obj, component );
        build( obj );
        
        assign_uniform_external_boundary_id( obj, id );
        assign_external_boundary_id( obj, id, interface_ids );
        
        % fn must have the form:
        %  v = fn( material_id )
        % where v and material_id are vectors of the same size
        % values will be a vector of length equal to the number of external
        % interfaces
        values = apply_external_bc_fns( obj, fns );
        
        % fn must have the form:
        %  v = fn( material_id )
        % where v and material_id have the same number of rows, and
        % material_id has 2 columns
        % values will be an array with number of rows equal to the number
        % of internal interfaces, and 2 columns
        values = apply_internal_bc_fns( obj, fns );
        
        % fn must have the form:
        %  v = fn( material_id );
        % where v and material_id are vectors of the same size
        % values will be a vector of length equal to the number of internal
        % interfaces
        values = apply_material_property_fn( obj, fn );
        
    end
    
end

