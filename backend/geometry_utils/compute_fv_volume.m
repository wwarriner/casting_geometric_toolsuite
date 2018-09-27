function volume = compute_fv_volume( fv )
 
    signed_volume = squeeze( dot( ...
        fv.vertices( fv.faces( :, 1 ), : ), ...
        cross( ...
            fv.vertices( fv.faces( :, 2 ), : ), ...
            fv.vertices( fv.faces( :, 3 ), : ) ...
            ) ...
        ) );
    volume = sum( signed_volume( : ) ) ./ 6.0;

end
