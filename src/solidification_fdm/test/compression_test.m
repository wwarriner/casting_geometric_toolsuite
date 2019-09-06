%% TEST CASE
%test_case

%% Spline stuff
t = ct.t;
temp = ct.u(:,21);

%% Testing

fh = figure();
axh = axes( fh );

k = 3;
TARGET = 0.01;

spg = SplineGenerator( k, t, temp );

bisector = BisectionTracker( ...
    25, ...
    0, ...
    inf, ...
    @(p)-(spg.generate(p)-TARGET), ...
    0, ...
    1e-4 ...
    );
MAX_ITERATION_COUNT = 50;
iteration_count = 0;
while true
    
    done = bisector.update();
    plot( axh, spg.x, spg.yy, 'b+', spg.x, spg.y, 'k.' );
    fprintf( 1, '%i, %.6f\n', bisector.x, spg.error );
    drawnow();
    if done
        break;
    end
    iteration_count = iteration_count + 1;
    if iteration_count > MAX_ITERATION_COUNT
        break;
    end
    
end

%%
a = spg.sp;

% if slm
a.stats = [];
a.prescription = [];
a.x = [];
a.y = [];
a.Extrapolation = [];

s = whos( 'a' );
compressed_space = s.bytes;
s = whos( 't' );
original_space = 2 * s.bytes;
compression_ratio = original_space ./ ( original_space + compressed_space );
fprintf( 1, 'Compression Ratio: %.2f%%\n', compression_ratio * 100 );


%% NOTES
% Efficient storage will rely on a global knot number
% for example if the knot number is 25, then we would store 75*#els data in an
% array
% How do we rebuild the data we need efficiently?
% Can we vectorize slmeval?
% What about optimizing the inverse problem?
