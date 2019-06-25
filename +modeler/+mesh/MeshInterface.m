classdef (Abstract) MeshInterface < handle
    
    methods ( Access = public )
        
        % returns the dimensionality of the mesh
        count = get_dimension_count( obj )
        
        % returns the number of elements in the mesh
        count = get_count( obj );
        
        % - returns a pair of vectors, both have length equal to the number
        % of neighboring pairs of elements
        % - the values in the vectors are indices that represent elements
        % in the mesh
        % - values are >= 0
        % - values at the same position in each vector are neighbors of
        % each other, and can never both be 0
        % - a value of 0 indicates the corresponding neighbor has an
        % external boundary
        connectivity = get_connectivity( obj );
        
        % - returns a vector with length equal to the number of elements
        % - the values represent materials via lookup id
        ids = get_material_ids( obj );
        
        % - returns a vector with length equal to the number of neighboring
        % pairs of elements
        % - the values in the vector represent external boundary conditions
        % via lookup id
        % - values are >= 0
        % - a value of 0 indicates no external boundary
        ids = get_external_boundary_ids( obj );
        
        % - returns a vector with length equal to the number of neighboring
        % pairs of elements
        % - the values in the vector represent internal boundary conditions
        % via lookup id
        % - the values are >= 0
        % - a value of 0 indicates no internal boundary
        ids = get_internal_boundary_ids( obj );
        
        % - returns a pair of vectors with length equal to the number of
        % neighboring pairs of elements
        % - the first vector contains the center-to-interface length
        % starting from elements in the first vector returned by
        % get_connectivity(), while the second vector contains the same
        % information starting from elements in the second vector
        % - the sum of the two vectors is the total center-to-center
        % distance of neighbor pairs
        distances = get_distances( obj );
        
        % - returns a vector with length equal to the number of neighboring
        % pairs of elements
        % - vector values correspond to interface area between neighboring
        % pairs of elements
        areas = get_interface_areas( obj );
        
        % - returns a vector with length equal to the number of elements
        % - vector values are the volums of each element
        volumes = get_element_volumes( obj );
        
    end
    
end

