%% Notice
% Copyright 2017-2018 by William E. Warriner

%% capped_cylinder: generate FV-struct representing cylinder with endcaps
%
% MATLAB built-in cylinder() function generates a cylinder with no end caps.
% This function generates a cylinder with end caps. Cylinder may be generated 
% using quads (default) or triangles. Unlike MATLAB built-in cylinder() 
% function, this function takes an additional height argument, and scales the 
% cylinder appropriately.
%
% Syntax:
%  fv = capped_cylinder( radius, number_of_segments )
%  fv = capped_cylinder( radius, height, number_of_segments )
%  fv = capped_cylinder( radius, height, number_of_segments, triangles )
%
% Inputs:
%  - radius: positive real cylinder radius
%  - number_of_segments: positive integer number of segments around cylinder
%   circumference, must be >= 3
%  - height: positive real cylinder height
%  - triangles: character vector or scalar string containing 'triangles' if
%   triangle faces are desired, otherwise quadrilaterals are generated
%
% Output:
%  - fv: Face-Vertex (FV) struct with two fields
%   - vertices: 3xN array of reals representing location of N cylinder vertices
%   - faces: QxM array of integers indexing into vertices, representing M
%    cylinder faces, each with Q associated vertices. Q is 3 if faces are 
%    triangles, 4 otherwise.

function fv = capped_cylinder( varargin )
%% Parse inputs
height = 1;
method = '';
switch nargin
    case 2
        [ radius, segments ] = deal( varargin{ : } );
    case 3
        [ radius, height, segments ] = deal( varargin{ : } );
    case 4
        [ radius, height, segments, method ] = deal( varargin{ : } );
    otherwise
        error( 'Incorrect arguments.\n' );
end
use_tris = strcmpi( 'triangles', method );

%% Generate transformed cylinder
[ x, y, z ] = cylinder( radius, segments );
if use_tris
    fv = surf2patch( x, y, z, 'triangles' );
else
    fv = surf2patch( x, y, z );
end
fv.vertices( :, 3 ) = height .* fv.vertices( :, 3 );

%% Generate caps
vertex_count = size( fv.vertices, 1 );
fv.faces( fv.faces == vertex_count - 1 ) = 1;
fv.faces( fv.faces == vertex_count ) = 2;
fv.vertices( end - 1 : end, : ) = [];
indices = ( 3 : 2 : size( fv.vertices, 1 ) ).';
common_index = ones( length( indices ), 1 );
lower = [ 
    indices ...
    circshift( indices, -1 ) ...
    common_index ...
    ];
if ~use_tris
    lower = [ ...
        lower ...
        common_index ...
        ];
end
lower = lower( 1 : end - 1, : );
upper = lower + 1;

%% Stitch caps
fv.faces = [ fv.faces; lower; upper ];

end

