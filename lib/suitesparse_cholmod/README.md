# SuiteSparse CHOLMOD
SuiteSparse without METIS stripped down to CHOLMOD only. Please see [SuiteSparse](http://faculty.cse.tamu.edu/davis/suitesparse.html) for more information. nAdded `spdiags2.m`, which is precisely `spdiags.m` with `sparse()` replaced by `sparse2()`.

#### To build:
0) Ensure you have a suitable C compiler installed on your system.
1) In MATLAB, CD to the repository root directory
2) Run `SuiteSparse_install()`
