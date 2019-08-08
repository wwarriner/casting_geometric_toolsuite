# MATLAB Capped Cylinder
Provides a function that creates a capped cylinder. The built-in MATLAB cylinder function creates only the circumferential wall of a cylinder, and no endcaps. The provided function stitches caps on the end of a MATLAB built-in cylinder. The resulting geometry is watertight and manifold, and therefore should work as stereolithography (STL) geometry if the optional `method` parameter is set to `'triangles'`.

# Usage
Ensure the function is on the MATLAB path. It may be used with 2, 3, or 4 arguments/
- Two arguments `r`, `n` are the radius and number of rectangular segments about the circumference.
- Three arguments `r`, `h`, `n`, are as above, with a height parameter.
- Four arguments `r`, `h`, `n`, `method`, are as above, with an additional character vector `method`. If `method` is equal to `'triangles'`, then the rectangular segments will be triangulated.

# Planned Updates
None at this time.
