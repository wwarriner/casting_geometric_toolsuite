function SuiteSparse_test
% SuiteSparse_test exhaustive test of all SuiteSparse packages
%
% Your current directory must be SuiteSparse for this function to work.
% SuiteSparse_install must be run prior to running this test.  Warning:
% this test takes a *** long **** time.
%
% Example:
%   SuiteSparse_test
%
% See also SuiteSparse_install, SuiteSparse_demo.

% Copyright 1990-2015, Timothy A. Davis, http://www.suitesparse.com.

help SuiteSparse_test

npackages = 19 ;
h = waitbar (0, 'SuiteSparse test:') ;
SuiteSparse = pwd ;
package = 0 ;

try

    %---------------------------------------------------------------------------
    % COLAMD
    %---------------------------------------------------------------------------

    package = package + 1 ;
    waitbar (package/(npackages+1), h, 'SuiteSparse test: COLAMD') ;
    cd ([SuiteSparse '/COLAMD/MATLAB']) ;
    colamd_test ;

    %---------------------------------------------------------------------------
    % CCOLAMD
    %---------------------------------------------------------------------------

    package = package + 1 ;
    waitbar (package/(npackages+1), h, 'SuiteSparse test: CCOLAMD') ;
    cd ([SuiteSparse '/CCOLAMD/MATLAB']) ;
    ccolamd_test ;

    %---------------------------------------------------------------------------
    % CHOLMOD
    %---------------------------------------------------------------------------

    package = package + 1 ;
    waitbar (package/(npackages+1), h, 'SuiteSparse test: CHOLMOD') ;
    cd ([SuiteSparse '/CHOLMOD/MATLAB/Test']) ;
    cholmod_test ;

    %---------------------------------------------------------------------------
    % MESHND
    %---------------------------------------------------------------------------

    package = package + 1 ;
    waitbar (package/(npackages+1), h, 'SuiteSparse test: MESHND') ;
    cd ([SuiteSparse '/MATLAB_Tools/MESHND']) ;
    meshnd_quality ;

catch

    %---------------------------------------------------------------------------
    % test failure
    %---------------------------------------------------------------------------

    cd (SuiteSparse) ;
    disp (lasterr) ;                                                        %#ok
    fprintf ('SuiteSparse test: FAILED\n') ;
    return

end

%-------------------------------------------------------------------------------
% test OK
%-------------------------------------------------------------------------------

close (h) ;
fprintf ('SuiteSparse test: OK\n') ;
cd (SuiteSparse) ;
