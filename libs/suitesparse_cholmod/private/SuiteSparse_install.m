function SuiteSparse_install (do_demo)
%SuiteSparse_install: compiles and installs all of SuiteSparse
% A Suite of Sparse matrix packages, authored or co-authored by Tim Davis.
%
% Packages in SuiteSparse:
%
% CHOLMOD        sparse Cholesky factorization, and many other operations
% AMD            sparse symmetric approximate minimum degree ordering
% COLAMD         sparse column approximate minimum degree ordering
% CAMD           constrained AMD
% CCOLAMD        constrained COLAMD
%
% Example:
%    SuiteSparse_install        % compile and prompt to run each package's demo
%    SuiteSparse_install(0)     % compile but do not run the demo
%    SuiteSparse_install(1)     % compile and run the demos with no prompts
%    help SuiteSparse           % for more details
%
% See also AMD, COLAMD, CAMD, CCOLAMD, CHOLMOD.
%
% This script installs the full-featured CXSparse rather than CSparse.
%
% Copyright 1990-2018, Timothy A. Davis, http://www.suitesparse.com.
% In collaboration with (in alphabetical order): Patrick Amestoy, David
% Bateman, Yanqing Chen, Iain Duff, Les Foster, William Hager, Scott Kolodziej,
% Stefan Larimore, Ekanathan Palamadai Natarajan, Sivasankaran Rajamanickam,
% Sanjay Ranka, Wissam Sid-Lakhdar, and Nuri Yeralan.
%
% Modified Feb 20 2019 by William Warriner
% - Stripped packages out that are not related to CHOLMOD

%-------------------------------------------------------------------------------
% initializations
%-------------------------------------------------------------------------------

paths = { } ;
SuiteSparse = fileparts( mfilename( 'fullpath' ) );

% determine the MATLAB version (6.1, 6.5, 7.0, ...)
v = version ;
pc = ispc ;

% print the introduction
help SuiteSparse_install

fprintf ('\nInstalling SuiteSparse for MATLAB version %s\n\n', v) ;

% add SuiteSparse to the path
paths = add_to_path (paths, SuiteSparse) ;

%-------------------------------------------------------------------------------
% compile and install the packages
%-------------------------------------------------------------------------------

% compile and install CHOLMOD
try
    paths = add_to_path (paths, [SuiteSparse '/CHOLMOD/MATLAB']) ;
    cholmod_make ;
catch me
    disp (me.message) ;
    fprintf ('CHOLMOD not installed\n') ;
end

% compile and install AMD
try
    paths = add_to_path (paths, [SuiteSparse '/AMD/MATLAB']) ;
    amd_make ;
catch me
    disp (me.message) ;
    fprintf ('AMD not installed\n') ;
end

% compile and install COLAMD
try
    paths = add_to_path (paths, [SuiteSparse '/COLAMD/MATLAB']) ;
    colamd_make ;
catch me
    disp (me.message) ;
    fprintf ('COLAMD not installed\n') ;
end

% compile and install CCOLAMD
try
    paths = add_to_path (paths, [SuiteSparse '/CCOLAMD/MATLAB']) ;
    ccolamd_make ;
catch me
    disp (me.message) ;
    fprintf ('CCOLAMD not installed\n') ;
end

% compile and install CAMD
try
    paths = add_to_path (paths, [SuiteSparse '/CAMD/MATLAB']) ;
    camd_make ;
catch me
    disp (me.message) ;
    fprintf ('CAMD not installed\n') ;
end

%-------------------------------------------------------------------------------
% post-install wrapup
%-------------------------------------------------------------------------------

cd (SuiteSparse)
fprintf ('SuiteSparse is now installed.\n\n') ;

% run the demo, if requested
if (nargin < 1)
    % ask if demo should be run
    y = input ('Hit enter to run the SuiteSparse demo (or "n" to quit): ', 's');
    if (isempty (y))
        y = 'y' ;
    end
    do_demo = (y (1) ~= 'n') ;
    do_pause = true ;
else
    % run the demo without pausing
    do_pause = false ;
end
if (do_demo)
    try
	SuiteSparse_demo ([ ], do_pause) ;
    catch me
        disp (me.message) ;
	fprintf ('SuiteSparse demo failed\n') ;
    end
end

% print the list of new directories added to the path
fprintf ('\nSuiteSparse installation is complete.  The following paths\n') ;
fprintf ('have been added for this session.  Use pathtool to add them\n') ;
fprintf ('permanently.  If you cannot save the new path because of file\n');
fprintf ('permissions, then add these commands to your startup.m file.\n') ;
fprintf ('Type "doc startup" and "doc pathtool" for more information.\n\n') ;
for k = 1:length (paths)
    fprintf ('addpath %s\n', paths {k}) ;
end
cd (SuiteSparse)

fprintf ('\nSuiteSparse for MATLAB %s installation complete\n', v) ;

%-------------------------------------------------------------------------------
function paths = add_to_path (paths, newpath)
% add a path
cd (newpath) ;
addpath (newpath) ;
paths = [paths { newpath } ] ;
