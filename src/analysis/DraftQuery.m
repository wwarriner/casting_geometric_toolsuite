classdef DraftQuery < handle
    % @DraftQuery computes the draft angles of faces represented by the input
    % normals. The intent is to determine the draft relative to the parting
    % direction.
    
    properties
        angles(:,1) double {mustBeReal,mustBeFinite}
        % TODO: draft metric of some sort
    end
    
    methods
        % Inputs:
        % - @normals is a real, finite double matrix which represents the
        % normals of faces from e.g. a face-vertex (fv) struct. Each row
        % represents the normal of one face, and each column represents one
        % dimension.
        % - @up_vector is a real, finite double vector which represents the up
        % direction to compare against the normals to determine draft angles.
        function obj = DraftQuery( normals, up_vector )
            obj.angles = compute_draft_angles( normals, up_vector );
        end
    end
    
end

