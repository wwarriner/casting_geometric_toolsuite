function  add_pretty_3d_axes( axes_handle, min_point, max_point, origin, scaling_factor )

if nargin < 4
    origin = zeros( size( min_point ) );
end
if nargin < 5
    scaling_factor = 1.2;
end

extrema = max( abs( [ max_point; min_point ] ), [], 1 );
max_point = extrema;
min_point = -extrema;
plot_axis_lines( axes_handle, max_point * scaling_factor, origin );
plot_axis_lines( axes_handle, min_point * scaling_factor, origin );
plot_text_labels( axes_handle, max_point, +1 );
plot_text_labels( axes_handle, min_point, -1 );

end


function plot_axis_lines( axes_handle, extrema, origin )

for i = 1 : 3
    
    extents = zeros( 3, 2 );
    extents( i, : ) = [ origin( i ) extrema( i ) ];
    plot3( ...
        axes_handle, ...
        extents( 1, : ), ...
        extents( 2, : ), ...
        extents( 3, : ), ...
        get_color( i ) ...
        );

end

end


function plot_text_labels( axes_handle, extrema, direction )

SCALING_FACTOR = 1.35;
extrema = extrema * SCALING_FACTOR;
for i = 1 : 3
    
    extents = zeros( 3, 1 );
    extents( i ) = extrema( i );
    handle = text( ...
        axes_handle, ...
        extents( 1 ), ...
        extents( 2 ), ...
        extents( 3 ), ...
        get_label_string( i, direction ) ...
        );
    format_text( handle, get_color( i ) );

end

end


function format_text( text_handle, color )

text_handle.Color = color;
text_handle.HorizontalAlignment = 'center';
text_handle.VerticalAlignment = 'middle';

end


function color = get_color( axis_index )

colors = { 'r', 'g', 'b' };
color = colors{ axis_index };

end


function label = get_label_string( axis_index, direction )

dimensions = { 'X', 'Y', 'Z' };
if direction < 0
    sign = '-';
elseif direction > 0
    sign = '+';
else
    assert( false );
end
label = sprintf( '%s%s', sign, dimensions{ axis_index } );

end



