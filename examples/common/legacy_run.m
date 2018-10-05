function data = legacy_run( op )
%% SETUP
names = cell( 1, 0 );
raw_data = cell( 1, 0 );

%% COMPONENT, MESH
[ names, raw_data, c ] = run_object( ...
    names, raw_data, ...
    Component(), ...
    op.input_stl_path ...
    );
[ names, raw_data, m ] = run_object( ...
    names, raw_data, ...
    Mesh(), ...
    c, op.element_count ...
    );

%% UNDERCUTS
for i = 1 : 3
    [ names, raw_data ] = run_object( ...
        names, raw_data, ...
        Undercuts(), ...
        m, i ...
        );
end

%% PARTING PERIMETER, WATERFALL
for i = 1 : 3
    [ names, raw_data, pp ] = run_object( ...
        names, raw_data, ...
        PartingPerimeter(), ...
        m, i ...
        );
    [ names, raw_data ] = run_object( ...
        names, raw_data, ...
        Waterfall(), ...
        m, pp, 'up' ...
        );
    [ names, raw_data ] = run_object( ...
        names, raw_data, ...
        Waterfall(), ...
        m, pp, 'down' ...
        );
end
clear pp;

%% EDT, THIN WALL, BOTTLE CORES
[ names, raw_data, e ] = run_object( ...
    names, raw_data, ...
    EdtProfile(), ...
    m ...
    );
[ names, raw_data ] = run_object( ...
    names, raw_data, ...
    BottleCores(), ...
    m, e ...
    );
[ names, raw_data ] = run_object( ...
    names, raw_data, ...
    CavityThinWall(), ...
    c, m, e, op.thin_wall_cavity_threshold, 'cavity' ...
    );
[ names, raw_data ] = run_object( ...
    names, raw_data, ...
    MoldThinWall(), ...
    c, m, e, op.thin_wall_mold_threshold, 'die' ...
    );

%% SEGMENTATION, FEEDERS
[ names, raw_data, s ] = run_object( ...
    names, raw_data, ...
    Segmentation(), ...
    e, m ...
    );
[ names, raw_data ] = run_object( ...
    names, raw_data, ...
    Feeders(), ...
    s, m ...
    );

%% CREATE TABLE
count = numel( raw_data );
assert( count == numel( names ) );
data = table;
for i = 1 : count
    data = merge_tables( data, raw_data{ i }, names{ i } );
end

end
