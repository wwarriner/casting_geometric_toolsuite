function peaks = gray_peaks( im )

regional_peaks = imregionalmax( im );
peaks = unique( im( regional_peaks ) );

end

