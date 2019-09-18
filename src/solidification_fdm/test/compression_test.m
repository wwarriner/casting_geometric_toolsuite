%% TEST CASE
%test_case

%% Spline stuff
t = ct.t;
temp = ct.u(:,21);

%% Testing
k = 3;
TARGET = 0.01;

spg = SplineGenerator( k, log(t+1), temp );

bisector = BisectionTracker( ...
    25, ...
    0, ...
    inf, ...
    @(p)-(spg.generate(p)-TARGET), ...
    0, ...
    1e-3 ...
    );
% x = ga( ...
%     @(p)-(spg.generate(p)-TARGET), ...
%     1, ... nvars
%     [], ... A
%     [], ... b
%     [], ...
%     [], ...
%     5, ... lb
%     500, ... ub
%     [], ... nonlcon
%     1 ... intcon
%     );

MAX_ITERATION_COUNT = 10;
iteration_count = 0;
while true
    
    done = bisector.update();
    fprintf( 1, '%i, %.6f\n', bisector.x, bisector.y );
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
fh = figure();
axh = axes( fh );
hold( axh, "on" );
%time = exp(spg.x)-1;
time = spg.x;
plot( axh, time, spg.yy, 'b', time, spg.y, 'k' );
sol = melt_m.solidus_temperature_c;
plot( axh, axh.XLim, [ sol sol ], 'k:' );
fe = melt_m.feeding_effectivity_temperature_c;
plot( axh, axh.XLim, [ fe fe ], 'k:' );
liq = melt_m.liquidus_temperature_c;
plot( axh, axh.XLim, [ liq liq ], 'k:' );

fh = figure();
axh = axes( fh );
plot( axh, time, 100 .* ( spg.y - spg.yy ) ./ spg.y, 'r' );

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
