# Casting Geometric Toolsuite
A suite of tools for geometric analysis of metal castings, based on the work of William Warriner (paper references tbd). The code is licensed under the MIT license, with the exception of some of the external libraries, which have their own licenses. Please see below.

# Usage
The code was written in version `R2018a` and is not guaranteed to work for any previous version.

For now, examine the examples/demo code. To install, ensure all of the subfolders are on the MATLAB path (you can use the `extend_search_path.m` script for this).

You will also need various libraries available on the MATLAB File Exchange, all of which must be on the MATLAB path. The libraries are included with the source and do not need to be downloaded. The library licenses are all BSD, with the exception of vtkwrite, which is MIT.

#### External Libraries
- [3D Euclidean Distance Transform for Variable Data Aspect Ratio](https://www.mathworks.com/matlabcentral/fileexchange/15455-3d-euclidean-distance-transform-for-variable-data-aspect-ratio) (bwdistsc, BSD)
- [Mesh voxelization](https://www.mathworks.com/matlabcentral/fileexchange/27390-mesh-voxelisation) (Mesh_voxelization, BSD)
- [A suite of minimal bounding objects](https://www.mathworks.com/matlabcentral/fileexchange/34767-a-suite-of-minimal-bounding-objects) (MinBoundSuite, BSD)
- [stlwrite - write ASCII or Binary STL files](https://www.mathworks.com/matlabcentral/fileexchange/20922-stlwrite-write-ascii-or-binary-stl-files) (stlwrite, BSD)
- [vtkwrite : Exports various 2D/3D data to ParaView in VTK file format](https://www.mathworks.com/matlabcentral/fileexchange/47814-vtkwrite-exports-various-2d-3d-data-to-paraview-in-vtk-file-format) (vtkwrite, MIT)
- [subtightplot](https://www.mathworks.com/matlabcentral/fileexchange/39664-subtightplot) (subtightplot, BSD)

The MATLAB toolboxes listed below are also required.

#### MATLAB Toolboxes
- [Image Processing Toolbox](https://www.mathworks.com/products/image.html)
- [Statistics and Machine Learning Toolbox](https://www.mathworks.com/products/statistics.html)
- [Mapping Toolbox](https://www.mathworks.com/products/mapping.html) (orientation optimization only)

#### Geometry Sources
- `base_plate.stl` is [casting by catia](https://grabcad.com/library/casting-by-catia-1) from [GrabCad](grabcad.com) by user [RiBKa aTIKA](https://grabcad.com/ribka.atika-1)
- `steering_column_mount.stl` is [Steering Column Mount](https://grabcad.com/library/steering-column-mount-1) from [GrabCad](grabcad.com) by user [Christian Mele](https://grabcad.com/christian.mele-1)
- `bearing_block.stl` is a 3D implementation of a 2D drawing from _Directional Solidification of Steel Castings_, R Wlodawer, Pergamon Press, Oxford, UK, 1966. ISBN: 9781483149110. Available from [Amazon](http://a.co/d/3Lwgh1f)
- `bottle.stl`, `ring.stl`, `sphere.stl`, `wedge.stl` are all my own creations and subject to the terms of the license of this repository.

# Analyses Available
- Feeders (geometry-based)
- Undercuts
- Non-slide cores (soluble cores in investment casting)
- Thin-wall (cavity and die/mold)
- Parting perimeter information
- Waterfall (geometry-based)

# Planned Updates
- Simple graphical user interface for analysis
- Orientation optimization tool
- Additional sample geometries
- Improved documentation
- Example visualizations
