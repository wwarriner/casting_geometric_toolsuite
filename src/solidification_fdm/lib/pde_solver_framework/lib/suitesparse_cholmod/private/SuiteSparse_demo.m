function SuiteSparse_demo (matrixpath, dopause)
%SUITESPARSE_DEMO a demo of all packages in SuiteSparse
%
% Example:
%   SuiteSparse_demo
%
% See also umfpack, cholmod, amd, camd, colamd, ccolamd, btf, klu, spqr,
%   CSparse, CXSparse, ldlsparse, mongoose

% Copyright 2016, Timothy A. Davis, http://www.suitesparse.com.
%
% Modified Feb 20 2019 by William Warriner
% - Stripped packages out that are not related to CHOLMOD

if (nargin < 1 || isempty (matrixpath) || ~ischar (matrixpath))
    try
	% older versions of MATLAB do not have an input argument to mfilename
	p = mfilename ('fullpath') ;
	t = strfind (p, '/') ;
	matrixpath = [ p(1:t(end)) 'CXSparse/Matrix' ] ;
    catch me    %#ok
	% mfilename failed, assume we're in the SuiteSparse directory
	matrixpath = 'CXSparse/Matrix' ;
    end
end

if (nargin < 2)
    dopause = false ;
end

if (dopause)
    input ('Hit enter to run the CHOLMOD demo: ', 's') ;
end
try
    cholmod_demo
catch me
    disp (me.message) ;
    fprintf ('CHOLMOD demo failed\n' )
end

if (dopause)
    input ('Hit enter to run the COLAMD demo: ', 's') ;
end
try
    colamd_demo
catch me
    disp (me.message) ;
    fprintf ('COLAMD demo failed\n' )
end

if (dopause)
    input ('Hit enter to run the CCOLAMD demo: ', 's') ;
end
try
    ccolamd_demo
catch me
    disp (me.message) ;
    fprintf ('CCOLAMD demo failed\n' )
end

if (dopause)
    input ('Hit enter to run the MESHND demo: ', 's') ;
end
try
    meshnd_example
catch me
    disp (me.message) ;
    fprintf ('MESHND demo failed\n' )
end
try
    quickdemo_spqr_rank
catch me
    disp (me.message) ;
    fprintf ('spqr_rank demo failed\n' )
end

fprintf ('\n\n---- SuiteSparse demos complete\n') ;
