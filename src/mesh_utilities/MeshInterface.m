classdef (Abstract) MeshInterface < handle
    
    properties ( Abstract, SetAccess = private, Dependent )
        connectivity(:,1) uint32 {mustBePositive}
        count(1,1) uint32
        volumes(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        distances(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
    end
    
    
    methods ( Abstract )
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
        
        values = apply_internal_interface_fns( obj, fns );
        
        % @apply_material_property_fn applies the material property
        % function or functions in @fns to the list of elements in the
        % mesh, returning a vector with the same number of elements as the
        % underlying mesh.
        % - @fns must be either a single function handle, applied uniformly
        % to all material ids, or a cell array of function handles, one per
        % material id in the mesh. Each function handle in @fns must be of
        % the form `values = fn( id, locations )` where id is a scalar
        % material id, locations is a logical vector indicating the
        % elements with that material id (for e.g. field lookup), and
        % values is a list of returns values of the same size as locations
        % assigned to @values in the appropriate elements.
        % - @values are the values of the applied function
        values = apply_material_property_fn( obj, fn );
        
        values = map( obj, fn );
        value = reduce( obj, fn );
        
    end
    
end

