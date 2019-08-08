function vtkcoloredfacewriter( ...
    filepath, ...
    file_title, ...
    scalar_title, ...
    fvc ...
    )

assert( ischar( file_title ) || isstring( file_title ) );
assert( ischar( scalar_title ) || isstring( scalar_title ) );

DOUBLE_SPEC = '%18.17e';

fid = fopen( filepath, 'W' );
fprintf( fid, '# vtk DataFile Version 2.0\n' );
if numel( file_title ) > 255
    warning( 'Title too long, truncated to 255 chars\n' );
    print_title = file_title( 1 : 255 );
else
    print_title = file_title;
end
fprintf( fid, '%s\n', print_title );
fprintf( fid, 'ASCII\n' );
fprintf( fid, 'DATASET POLYDATA\n' );
point_count = size( fvc.vertices, 1 );
POINT_FORMAT = 'double';
fprintf( fid, 'POINTS %d %s\n', point_count, POINT_FORMAT );
point_spec_string = [ DOUBLE_SPEC ' ' DOUBLE_SPEC ' ' DOUBLE_SPEC '\n' ];
for i = 1 : point_count
    
    fprintf( ...
        fid, point_spec_string, ...
        fvc.vertices( i, 1 ), ...
        fvc.vertices( i, 2 ), ...
        fvc.vertices( i, 3 ) ...
        );
    
end
poly_count = size( fvc.faces, 1 );
TRIANGLE_POINT_COUNT = 3;
poly_element_count = ( TRIANGLE_POINT_COUNT + 1 ) * poly_count;
fprintf( fid, 'POLYGONS %d %d\n', poly_count, poly_element_count );
for i = 1 : poly_count
    
    % vtk start index == 0, hence - 1
    fprintf( ...
        fid, '%d %d %d %d\n', ...
        TRIANGLE_POINT_COUNT, ...
        fvc.faces( i, : ) - 1 ...
        );
    
end

SCALAR_FORMAT = 'double';
COMPONENT_COUNT = 1;
fprintf( fid, 'CELL_DATA %d\n', poly_count );
fprintf( ...
    fid, 'SCALARS %s %s %d\n', ...
    scalar_title, ...
    SCALAR_FORMAT, ...
    COMPONENT_COUNT ...
    );
fprintf( fid, 'LOOKUP_TABLE default\n' );
for i = 1 : poly_count
    
    fprintf( fid, [ DOUBLE_SPEC '\n' ], fvc.facevertexcdata( i ) );
    
end

fclose( fid );

end

