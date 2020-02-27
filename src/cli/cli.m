function out = cli( varargin )

out = 0;

[ parameters, parse_out ] = parse_inputs( varargin{:} );
if isempty( parameters )
    out = parse_out;
    return;
end

try
    settings = Settings( parameters.settings_file );
catch e
    out = 1;
    disp( getReport( e, "extended" ) );
    return;
end

try
    pm = ProcessManager( settings );
catch e
    out = 2;
    disp( getReport( e, "extended" ) );
    return;
end

if parameters.analyze
    try
        pm.run();
    catch e
        out = 3;
        disp( getReport( e, "extended" ) );
        return;
    end
    
    try
        pm.write_all();
    catch e
        out = 4;
        disp( getReport( e, "extended" ) );
        return;
    end
end

if parameters.view
    try
        p = Paraview( settings );
        p.casting_name = pm.name;
        p.input_folder = pm.write_folder;
        p.open();
    catch e
        out = 5;
        disp( getReport( e, "extended" ) );
        return;
    end
end

end


function [ parameters, out ] = parse_inputs( varargin )

parameters = [];
out = 0;

% PARSE POSITIONAL ARG
% MAY BE SETTINGS FILE PATH OR -h
if nargin < 1
    show_help();
    return;
else
    first = string( varargin{ 1 } );
end

if first == "-h"
    show_help();
    return;
elseif ~isfile( first )
    fprintf( 1, "Could not locate input settings file." + newline );
    out = 64;
    show_help();
    return;
else
    settings_file = first;
end

% PARSE OPTIONAL FLAGS
% MUST BE MODE, CONTAINS ANY COMBINATION OF -a and -v
if nargin < 2
    mode = "-av";
else
    mode = string( varargin( 2 : end ) );
end

mode = strjoin( mode, "" );
mode = char( mode );
mode = unique( mode );
mode = sort( mode );
VALID_TOKENS = 'av';
tokens = intersect( mode, VALID_TOKENS );
if mode(1) ~= '-' || numel(mode) <= 1 || isempty( tokens )
    fprintf( 1, "Could not understand mode flags." + newline );
    out = 65;
    show_help();
    return;
end

analyze = false;
if contains( mode, "a" )
    analyze = true;
end

view = false;
if contains( mode, "v" )
    view = true;
end

parameters.analyze = analyze;
parameters.view = view;
parameters.settings_file = settings_file;

end


function show_help()
    help_text = ...
        "First argument must be path to valid settings file or -h." + newline ...
        + " -h shows this message" + newline ...
        + newline ...
        + "Additional arguments are optional, and indicate operating mode." + newline ...
        + " -a performs analysis" + newline ...
        + " -v starts ParaView" + newline ...
        + "These may be combined as -av." + newline ...
        + "If no optional arguments are supplied, the program behaves as though -av were supplied." + newline ...
        + "-v only works if there are valid output files at the output location provided in the" + newline ...
        + "config file for the provided input." + newline ...
        + newline;
    fprintf( 1, help_text )
end
