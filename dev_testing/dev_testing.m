op = Options( '', which( 'legacy_demo_options.json' ) );
op.input_stl_path = 'C:\Users\wwarr\Desktop\legacy_test\cummins_qsf_3_9_diesel_engine_1_19.STL';
angles = [ 0 pi/2 ];
run( which( 'legacy_run_script.m' ) );
clear( 'angles' );
c = data.get( Component.NAME );
cv = Component(); cv.legacy_run( 'convex_hull', c.convex_hull_fv );
delta = ComponentDelta( c, cv, op.element_count );
m = data.get( Mesh.NAME );

%% DISTANCE FIELD
interior = delta.delta == delta.get_shared_value();
potential_cores = delta.delta == delta.REVISED_VALUE;
exterior = delta.delta == delta.EXTERIOR;
%test = bwdistgeodesic( potential_cores | interior | exterior, interior );
df = bwdistsc( interior | exterior );
df( ~potential_cores ) = 0;

%% FILTERING
max_edt = max( df( : ) );
normalized_edt = df ./ max_edt;
TOLERANCE = 1e-4;
height = ( 1 + TOLERANCE ) / max_edt;
filt = max_edt .* imhmax( normalized_edt, height );

%% WATERSHED
ws_filt = filt;
ws_filt( ~potential_cores ) = -inf;
segments_f = double( watershed( -ws_filt ) );
segments_f( ~potential_cores ) = 0;
segments_f( ...
    potential_cores ...
    & segments_f <= 0 ...
    ) ...
    = -1;

%% ALTERNATE METHOD
% TODO test this method vs segments_f
%
% TODO is it possible to make use of ulterode for anything related to
% segmentation, filtering, etc?
% Ulterode
% ult = bwulterode( filt );
% geod = bwdistgeodesic( potential_cores | exterior, ult );
% geod( ~potential_cores ) = 0;
% geod = max( geod( : ) ) - geod;
% 
% max_edt = max( geod( : ) );
% normalized_edt = geod ./ max_edt;
% TOLERANCE = 1e-4;
% height = ( 1 + TOLERANCE ) / max_edt;
% geod = max_edt .* imhmax( normalized_edt, height );
%
% ws_geod = geod;
% ws_geod( ~potential_cores ) = -inf;
% segments_g = double( watershed( -ws_geod ) );
% segments_g( ~potential_cores ) = 0;
% segments_g( ...
%     potential_cores ...
%     & segments_g <= 0 ...
%     ) ...
%     = -1;

%% CORE SEGMENTATION CLEANING
starting_core_segments = segments_f;
segment_count = max( starting_core_segments( : ) );
total_pixel_count = sum( potential_cores( : ) );
cc_pixel_counts = arrayfun( @(y)sum(starting_core_segments(:)==y), 1 : segment_count );
cc_volume_ratios = cc_pixel_counts ./ total_pixel_count;
indices_to_remove = cc_volume_ratios < 1/1000;
cleaned_segments = starting_core_segments;
for i = 1 : segment_count
    if indices_to_remove( i )
        cleaned_segments( cleaned_segments == i ) = 0;
    end
end

%% UNDERCUT CLEANING
undercuts = data.get( Undercuts.NAME ).array;
cc = bwconncomp( undercuts, conndef( 3, 'minimal' ) );
undercut_segments = double( labelmatrix( cc ) );
undercut_count = cc.NumObjects;
total_pixel_count = sum( undercuts( : ) );
cc_pixel_counts = arrayfun( @(y)sum(undercut_segments(:)==y), 1 : undercut_count );
cc_volume_ratios = cc_pixel_counts ./ total_pixel_count;
indices_to_remove = cc_volume_ratios < 1/1000;
cleaned_undercuts = undercut_segments;
for i = 1 : undercut_count
    if indices_to_remove( i )
        cleaned_undercuts( cleaned_undercuts == i ) = 0;
    end
end
new_undercuts = double( cleaned_undercuts > 0 );

%% DELETING CORE SEGMENTS THAT DONT OVERLAP UNDERCUTS
undercut_segment_mask = ( cleaned_segments > 0 ) + ( cleaned_segments & cleaned_undercuts );
cc = bwconncomp( undercut_segment_mask > 0, conndef( 3, 'minimal' ) );
undercut_segments = double( labelmatrix( cc ) );
undercut_only = undercut_segments;
for i = 1 : cc.NumObjects
    if ~sum( undercut_segments == i & cleaned_undercuts )
        undercut_only( undercut_segments == i ) = 0;
    end
end

%% Thing of interest
% slicing + bwdistgeodesic has been slow in the past, make sure this works well
% at higher resolutions
thing = new_undercuts > 0 | cleaned_undercuts;
cleaned_thing = thing;
for i = 1 : size( thing, DIMENSION )
    
    cc = bwconncomp( thing( :, :, i ), conndef( 2, 'minimal' ) );
    uc_slice = cleaned_undercuts( :, :, i );
    ext_slice = m.exterior( :, :, i );
    ccs_to_remove = cellfun( @(x)~any( uc_slice( x ) ), cc.PixelIdxList );
    current_slice = cleaned_thing( :, :, i );
    for j = 1 : cc.NumObjects
        if ccs_to_remove( j )
            current_slice( cc.PixelIdxList{ j } ) = 0;
        end
    end
    t = bwdistgeodesic( current_slice | uc_slice | ext_slice, logical( uc_slice ) );
    current_slice = current_slice | ext_slice;
    current_slice( t > 10 ) = 0;
    cleaned_thing( :, :, i ) = current_slice;
    
end
cc = bwconncomp( cleaned_thing, conndef( 3, 'minimal' ) );
core_like_segments = labelmatrix( cc );
for i = 1 : cc.NumObjects
    
    current_segment = core_like_segments == i;
    core_like_segments( current_segment ) = 0;
    current_segment = imclose( current_segment, conndef( 3, 'minimal' ) ); %strel( 'sphere', 5 )
    core_like_segments( current_segment ) = i;
    
end
core_like_segments( interior ) = 0;
% needs cleanup like above routine

%% Visualize
volumeViewer( double( core_like_segments > 0 ) - double( core_like_segments > 0 & new_undercuts ) + 2*new_undercuts + 3*interior );
volumeViewer( core_like_segments );
