function dc = sig_fig_digit_count( floating_point_value, significant_figures )

dc = count_leading_zeros( floating_point_value ) + significant_figures;

end

