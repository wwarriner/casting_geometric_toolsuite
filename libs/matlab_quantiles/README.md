# MATLAB Quantiles

A utility for determining quantiles and associated values from a cumulative distribution function (CDF) represented as a vector of numerical values and an optional vector of numerical weights. It is possible to convert a vector of quantiles into a vector of associated CDF values. It is also possible to convert a vector of CDF values into associated quantiles. The weight for a given index is the probability of finding a value between current and next index, and the last weight is ignored.

# Usage

To convert from quantiles to values (divisions) and back:

`quants = div_to_quant( divs, values, weights = ones( size( values ) ), interpolation_method = 'linear' );`

`divs = quant_to_div( quants, values, weights = ones( size( values ) ), interpolation_method = 'linear' );`

To plot the CDF:

`handles = plot_quantiles( quantiles, values, weights = ones( size( values ) ), interpolation_method = 'linear' );`

`handles = plot_divisions( divisions, values, weights = ones( size( values ) ), interpolation_method = 'linear' );`

`handles = plot_*( axes_handle, ___ );`
