classdef (Abstract) MeshInterface < handle
    
    methods ( Access = public )
        
        % returns the dimensionality of the mesh
        count = get_dimension_count( obj )
        
        % returns the number of elements in the mesh
        count = get_count( obj );
        
        % - returns a logical sparse connectivity matrix indicating elements
        % with a shared interface
        % - returned array has rows equal to number of elements in indices and
        % columns equal to get_count()
        % - row/column pairs that have a true value indicate that the element
        % denoted by the row index shares an interface with the element denoted
        % by the column index
        % - indices must be a vector
        % - indices must only contain values ranging from 1 to get_count()
        connectivity = get_connectivity( obj, indices );
        
        % TODO boundary conditions!
        
        % - materials contains the material identifiers of elements denoted by
        % indices
        % - indices must be a vector
        % - indices must only contain values ranging from 1 to get_count()
        material_ids = get_material_ids( obj, indices );
        
        % - lhs return value is distance from center of elements denoted by 
        % indices to all their respective neighbors, returned as a sparse double
        % matrix of the same shape as would be returned by get_connectivity()
        % - values are in the appropriate positions given by true values of
        % get_connectivity
        % - indices must be a vector
        % - indices must only contain values ranging from 1 to get_count()
        [ lhs, rhs ] = get_distances( obj, indices );
        
        % - areas contains interface area between elements denoted by 
        % indices to all their respective neighbors, returned as a sparse double
        % matrix of the same shape as would be returned by get_connectivity()
        % - values are in the appropriate positions given by true values of
        % get_connectivity
        % - indices must be a vector
        % - indices must only contain values ranging from 1 to get_count()
        areas = get_interface_areas( obj, lhs_indices, rhs_indices );
        
        % - volumes contains the volumes of elements denoted by indices
        % - volumes is a vector the same size as indices
        % - indices must be a vector
        % - indices must only contain values ranging from 1 to get_count()
        volumes = get_element_volumes( obj, indices );
        
    end
    
end

