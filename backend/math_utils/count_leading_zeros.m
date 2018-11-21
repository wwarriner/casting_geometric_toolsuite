function leading_zero_count = count_leading_zeros( floating_point_value )

if floating_point_value < 1
    leading_zero_count = -floor( log10( floating_point_value ) ) - 1;
else
    leading_zero_count = 0;
end

end

