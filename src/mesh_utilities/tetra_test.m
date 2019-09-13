s = StlFile( which( "bearing_block.stl" ) );
b = Body( s.fv );
tm = TetrahedralMesh( b, 1 );
