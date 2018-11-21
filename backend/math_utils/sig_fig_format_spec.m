function format_spec = sig_fig_format_spec( floating_point_value, significant_figures, digit_cutoff )

if nargin < 3
    digit_cutoff = 4;
end

digit_count = sig_fig_digit_count( floating_point_value, significant_figures );
if digit_count >= digit_cutoff
    format_spec = sprintf( '%%.%ie', significant_figures - 1 );
else
    format_spec = sprintf( '%%.%if', digit_cutoff );
end

end

