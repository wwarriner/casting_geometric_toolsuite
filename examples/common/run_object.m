function [ results, runnable ] = run_object( ...
    results, ...
    runnable, ...
    varargin ...
    )

runnable.legacy_run( varargin{ : } );
results.add( runnable.NAME, runnable );

end

