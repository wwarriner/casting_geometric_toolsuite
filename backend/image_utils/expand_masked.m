function image = expand_masked( image, mask, threshold )
% @expand_masked functions similarly to dilation, but operates using the
% quasi-euclidean geodesic distance, forcing it to traverse around
% boundaries.
% Inputs:
% - @image is a logical array representing the image to be expanded.
% - @mask is a logical array of the same size as @image, representing the
% boundaries.
% - @threshold is a scalar double and has mesh length units, representing
% the cutoff for expansion distance.

distances = bwdistgeodesic( mask, image, 'quasi-euclidean' );
image( distances > threshold ) = 0;
image( ~mask ) = 0;

end

