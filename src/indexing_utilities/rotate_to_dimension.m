% permutes the dimensions of n-d array so that the dimension associated with the 
% value of input "dimension" is in "position", and also returns inverse
% permutation order
function [ array, inverse ] = rotate_to_dimension( dimension, array, position )

if nargin < 3
    position = 1;
end

rotated_dimensions = circshift( 1 : ndims( array ), position - dimension );
array = permute( array, rotated_dimensions );
inverse = rotated_dimensions;

end

