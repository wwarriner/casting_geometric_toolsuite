# Casting Geometric Toolsuite
A suite of tools for geometric analysis of metal castings.
Based on the work of William Warriner (paper references tbd).

# Usage
For now, examine the examples/demo code. To install, ensure all of the subfolders are on the MATLAB path (you can use the `extend_search_path.m` script for this). You will also need various libraries available on the MATLAB File Exchange, all of which must be on the MATLAB path. These include:
- [3D Euclidean Distance Transform for Variable Data Aspect Ratio](https://www.mathworks.com/matlabcentral/fileexchange/15455-3d-euclidean-distance-transform-for-variable-data-aspect-ratio)
- [Mesh voxelization](https://www.mathworks.com/matlabcentral/fileexchange/27390-mesh-voxelisation)
- [A suite of minimal bounding objects](https://www.mathworks.com/matlabcentral/fileexchange/34767-a-suite-of-minimal-bounding-objects)
- [stlwrite - write ASCII or Binary STL files](https://www.mathworks.com/matlabcentral/fileexchange/20922-stlwrite-write-ascii-or-binary-stl-files)
- [vtkwrite : Exports various 2D/3D data to ParaView in VTK file format](https://www.mathworks.com/matlabcentral/fileexchange/47814-vtkwrite-exports-various-2d-3d-data-to-paraview-in-vtk-file-format)

# Analyses Available
- Feeders (geometry-based)
- Undercuts
- Non-slide cores (soluble cores in investment casting)
- Thin-wall (cavity and die/mold)
- Parting perimeter information
- Waterfall (geometry-based)

# Planned Updates
- Simple graphical user interface for analysis
- Additional sample geometries
- Orientation optimization example
- Improved documentation
