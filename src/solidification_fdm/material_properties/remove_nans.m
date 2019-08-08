function [ temperatures, values ] = remove_nans( temperatures, values )

ok_rows = ~isnan( temperatures ) & ~isnan( values );
temperatures = temperatures( ok_rows );
values = values( ok_rows );

end

