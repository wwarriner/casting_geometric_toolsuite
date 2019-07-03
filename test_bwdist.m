rng( 314159 );

shape = [ 100 100 100 ];
p = 0.05;
z = -sqrt( 2 ) * erfcinv( p * 2 );

count = 10;
time_bwdist = nan( count, 1 );
for i = 1 : count
    a = randn( shape ) < z;
    tic;
    b = bwdist( a );
    time_bwdist( i ) = toc; 
end

time_bwdistsc = nan( count, 1 );
for i = 1 : count
    a = randn( shape ) < z;
    tic;
    c = bwdistsc( a );
    time_bwdistsc( i ) = toc; 
end