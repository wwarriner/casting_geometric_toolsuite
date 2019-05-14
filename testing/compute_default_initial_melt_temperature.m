function initial_melt_temperature = compute_default_initial_melt_temperature( melt )

t = melt.get_liquidus_temperature();
initial_melt_temperature = t * 1.05;

end

