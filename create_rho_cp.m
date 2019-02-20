function rho_cp = create_rho_cp( rho, cp, k )

rho_cp_t = unique( [ rho.temperatures cp.temperatures k.temperatures ] );
rho_v = rho.lookup( rho.temperatures );
cp_v = cp.lookup( cp.temperatures );

rho_v = rho_v * cp_v;
rho_cp = MaterialProperty( rho_cp_t, rho_v );

end

