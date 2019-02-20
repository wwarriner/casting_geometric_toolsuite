function [ m_l, m_r, times ] = crank_nicolson_matrix( mesh, u, rho_cp, k, space_step, time_step )
%% setup
shape = size( mesh );
elts = prod( shape );
strides = [ 1 shape( 1 ) shape( 1 ) * shape( 2 ) ];

%% property lookup
tic;
rho_cps = zeros( shape );
ks = zeros( shape );

mold_id = 1;
rho_cps( mesh == mold_id ) = rho_cp( mold_id, u( mesh == mold_id ) );
ks( mesh == mold_id ) = k( mold_id, u( mesh == mold_id ) );

melt_id = 2;
rho_cps( mesh == melt_id ) = rho_cp( melt_id, u( mesh == melt_id ) );
ks( mesh == melt_id ) = k( melt_id, u( mesh == melt_id ) );

rho_cps = rho_cps * time_step / ( space_step ^ 2 );
c = ( 1 : elts ).';
rho_cp_c = rho_cps( c );
k_c = ks( c );
times( 1 ) = toc;

%% construct bands
tic;
rho_cp_u = [ ...
    mean( [ rho_cp_c circshift( rho_cp_c, strides( 1 ) ) ], 2 ) ...
    mean( [ rho_cp_c circshift( rho_cp_c, strides( 2 ) ) ], 2 ) ...
    mean( [ rho_cp_c circshift( rho_cp_c, strides( 3 ) ) ], 2 ) ...
    ];
k_c_flip = 0.5 ./ k_c;
k_u = [ ...
    k_c_flip + circshift( k_c_flip, strides( 1 ) ) ...
    k_c_flip + circshift( k_c_flip, strides( 1 ) ) ...
    k_c_flip + circshift( k_c_flip, strides( 1 ) ) ...
    ];
alpha_u = rho_cp_u .* k_u;

rho_cp_l = [ ...
    mean( [ rho_cp_c circshift( rho_cp_c, -strides( 1 ) ) ], 2 ) ...
    mean( [ rho_cp_c circshift( rho_cp_c, -strides( 2 ) ) ], 2 ) ...
    mean( [ rho_cp_c circshift( rho_cp_c, -strides( 3 ) ) ], 2 ) ...
    ];
k_l = [ ...
    k_c_flip + circshift( k_c_flip, -strides( 1 ) ) ...
    k_c_flip + circshift( k_c_flip, -strides( 1 ) ) ...
    k_c_flip + circshift( k_c_flip, -strides( 1 ) ) ...
    ];
alpha_l = rho_cp_l .* k_l;
times( 2 ) = toc;

%% construct sparse
tic;
m_off = spdiags2( [ alpha_l alpha_u ], [ -strides strides ], elts, elts );
m_r = spdiags2( 2 - sum( alpha_l, 2 ) - sum( alpha_u, 2 ), 0, elts, elts ) + m_off;
m_l = spdiags2( 2 + sum( alpha_l, 2 ) + sum( alpha_u, 2 ), 0, elts, elts ) - m_off;
times( 3 ) = toc;

%% construct bc vectors
%tic;
% r = zeros( elts, 1 );
% 
% xn = 1 : strides( 2 ) : elts;
% xp = strides( 2 ) : strides( 2 ) : elts;
% xx = [ xn xp ];
% r( xx ) = r( xx ) + rho_cps( xx ) ./ ks( xx ) .* ambient;
% 
% yn = reshape( repmat( ( 1 : strides( 2 ) ).', [ 1 shape( 2 ) ] ) + ( 1 : strides( 3 ) : elts ) - 1, 1, [] );
% yp = reshape( repmat( ( 1 : strides( 2 ) ).', [ 1 shape( 2 ) ] ) + ( strides( 3 ) - strides( 2 ) : strides( 3 ) : elts ), 1, [] );
% yy = [ yn yp ];
% r( yy ) = r( yy ) + rho_cps( yy ) ./ ks( yy ) .* ambient;
% 
% zn = 1 : strides( 3 );
% zp = elts - strides( 3 ) + 1 : elts;
% zz = [ zn zp ];
% r( zz ) = r( zz ) + rho_cps( zz ) ./ ks( zz ) .* ambient;
% 
% r_r = rx + ry + rz;
% r_l = -r_r
%fprintf( 'bc vector construct: %.2f\n', toc );

%fprintf( '%d%d\n', all(eig(m)>0), issymmetric(m) );

end
