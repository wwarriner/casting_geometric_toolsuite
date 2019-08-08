function path = get_deployed_executable_path()

% HACK this is brittle if MATLAB changes the way it deploys
if isdeployed() % Stand-alone mode.
    [ ~, result ] = system( 'path' );
    path = char( regexpi( result, 'Path=(.*?);', 'tokens', 'once') );
else % MATLAB mode.
    path = pwd();
end
    
end