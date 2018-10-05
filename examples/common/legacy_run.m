function data = legacy_run( op )
%% SETUP
names = cell( 1, 0 );
raw_data = cell( 1, 0 );

%% MESHING
c = Component();
c.legacy_run( op.input_stl_path );
names{ end + 1 } = c.get_storage_name();
raw_data{ end + 1 } = c.to_summary();

m = Mesh();
m.legacy_run( c, op.element_count );
names{ end + 1 } = m.get_storage_name();
raw_data{ end + 1 } = m.to_summary();

%% UNDERCUTS
for i = 1 : 3
    u = Undercuts();
    u.legacy_run( m, i );
    names{ end + 1 } = u.get_storage_name();
    raw_data{ end + 1 } = u.to_summary();
end
clear u;

%% PARTING PERIMETER, WATERFALL
for i = 1 : 3
    pp = PartingPerimeter();
    pp.legacy_run( m, i );
    names{ end + 1 } = pp.get_storage_name();
    raw_data{ end + 1 } = pp.to_summary();
    
    wf = Waterfall();
    wf.legacy_run( m, pp, 'up' );
    names{ end + 1 } = wf.get_storage_name();
    raw_data{ end + 1 } = wf.to_summary();
    
    wf = Waterfall();
    wf.legacy_run( m, pp, 'down' );
    names{ end + 1 } = wf.get_storage_name();
    raw_data{ end + 1 } = wf.to_summary();
end
clear pp;
clear wf;

%% EDT, THIN WALL, BOTTLE CORES
e = EdtProfile();
e.legacy_run( m );
names{ end + 1 } = e.get_storage_name();
raw_data{ end + 1 } = e.to_summary();

thin_cavity = CavityThinWall();
thin_cavity.legacy_run( c, m, e, op.thin_wall_cavity_threshold, 'cavity' );
names{ end + 1 } = thin_cavity.get_storage_name();
raw_data{ end + 1 } = thin_cavity.to_summary();
clear thin_cavity;

thin_die = MoldThinWall();
thin_die.legacy_run( c, m, e, op.thin_wall_mold_threshold, 'die' );
names{ end + 1 } = thin_die.get_storage_name();
raw_data{ end + 1 } = thin_die.to_summary();
clear thin_die;

bc = BottleCores();
bc.legacy_run( m, e );
names{ end + 1 } = bc.get_storage_name();
raw_data{ end + 1 } = e.to_summary();
clear bc;

%% SEGMENTATION, FEEDERS
s = Segmentation();
s.legacy_run( e, m );
names{ end + 1 } = s.get_storage_name();
raw_data{ end + 1 } = s.to_summary();

f = Feeders();
f.legacy_run( s, m );
names{ end + 1 } = f.get_storage_name();
raw_data{ end + 1 } = f.to_summary();

%% CREATE TABLE
count = numel( raw_data );
assert( count == numel( names ) );
data = table;
for i = 1 : count
    data = merge_tables( data, raw_data{ i }, names{ i } );
end

end
