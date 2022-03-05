# Casting Geometric Toolsuite
A suite of tools for geometric analysis of metal castings, based on the work of William Warriner (paper references tbd). The code is licensed under the MIT license, with the exception of some of the external libraries, which have their own licenses. Please see below.

The general concept is the integration of various image processing algorithms and a solidification FDM solver to identify points of interest in casting solid models. Many tools exist to generate what we call solidification fields, i.e. how long it takes each point to solidify, or what temperature they are at any given point in time. What does not exist, until now, is a way to identify the points that have the greatest impact on cost. This software seeks to assist engineers by annotating where they should focus their attention to produce more robust casting designs.

# Usage
The code was written in version `R2018a` and is not guaranteed to work for any previous version.

For now, examine the code in the `examples` subdirectory. To install, ensure all of the subfolders are on the MATLAB `PATH` (you can use the `extend_search_path.m` script for this).

You will also need various libraries available on the MATLAB File Exchange, all of which must be on the MATLAB `PATH`. The libraries are included with the source and do not need to be downloaded. The libraries are _not_ subject to the license of this repository. If you intend to use any of the libraries, they are subject to their own licenses.

Various MATLAB toolboxes are also required, which are detailed in the sources section.

#### Analyses Available
- Feeders (geometry-based)
- Undercuts
- Non-slide cores (soluble cores in investment casting)
- Thin-wall (cavity and die/mold)
- Parting perimeter information
- Waterfall (geometry-based)

# Orientation Optimization

Added on 28 Nov 2018 is an orientation plotting tool. The tool plots casting orientation objectives on two hemispherical projections. The tool allows selection of objective, visualizing objective-specific minima, pareto front points, and single quantile thresholding. A button is available to generate a visualization of the orientation of the casting. Three sample data sets are available, and can be visualized by calling `plot_sample_data()` in the `examples/optimization_demo/sample_data` folder. Each data set has 1656 decision variable sets and 11 objectives for each. The data was generated using a mesh count of `8e7`, and took about 400 hours of CPU time per data set. The data was not generated by any optimization method, but rather by brute force. It is believed that a direct search (i.e. by `pareto_search()` in R2018b) would be faster. It is possible to generate data sets for your own geometries, but would require some work. If you are interested in going down that route, please contact me.

See [here](https://github.com/wwarriner/casting_orientation_optimization).

# Sources

#### External Libraries
- [CDF Quantiles](https://www.mathworks.com/matlabcentral/fileexchange/70274-cdf-quantiles) (matlab_quantiles, UNLICENSE)
- [Mesh voxelization](https://www.mathworks.com/matlabcentral/fileexchange/27390-mesh-voxelisation) (Mesh_voxelization, BSD)
- [A suite of minimal bounding objects](https://www.mathworks.com/matlabcentral/fileexchange/34767-a-suite-of-minimal-bounding-objects) (MinBoundSuite, BSD)
- [Perceptually uniform colormaps](https://www.mathworks.com/matlabcentral/fileexchange/51986-perceptually-uniform-colormaps) (perceptually_uniform_colormaps, [custom license](https://github.com/matplotlib/matplotlib/blob/master/LICENSE/LICENSE))
- [PrettyAxes3DMatlab](https://www.mathworks.com/matlabcentral/fileexchange/69552-prettyaxes3dmatlab) (PrettyAxes3DMatlab, UNLICENSE)
- [stlwrite - write ASCII or Binary STL files](https://www.mathworks.com/matlabcentral/fileexchange/20922-stlwrite-write-ascii-or-binary-stl-files) (stlwrite, BSD)
- [subtightplot](https://www.mathworks.com/matlabcentral/fileexchange/39664-subtightplot) (subtightplot, BSD)
- [vtkwrite : Exports various 2D/3D data to ParaView in VTK file format](https://www.mathworks.com/matlabcentral/fileexchange/47814-vtkwrite-exports-various-2d-3d-data-to-paraview-in-vtk-file-format) (vtkwrite, MIT)

#### MATLAB Toolboxes
- [Image Processing Toolbox](https://www.mathworks.com/products/image.html)
- [Statistics and Machine Learning Toolbox](https://www.mathworks.com/products/statistics.html)
- [Mapping Toolbox](https://www.mathworks.com/products/mapping.html) (orientation optimization only)

#### Geometry Sources
- `base_plate.stl` is [casting by catia](https://grabcad.com/library/casting-by-catia-1) from [GrabCad](www.grabcad.com) by user [RiBKa aTIKA](https://grabcad.com/ribka.atika-1)
- `steering_column_mount.stl` is [Steering Column Mount](https://grabcad.com/library/steering-column-mount-1) from [GrabCad](www.grabcad.com) by user [Christian Mele](https://grabcad.com/christian.mele-1)
- `bearing_block.stl` is a 3D implementation of a 2D drawing from _Directional Solidification of Steel Castings_, R Wlodawer, Pergamon Press, Oxford, UK, 1966. ISBN: 9781483149110. Available from [Amazon](http://a.co/d/3Lwgh1f)
- `bottle.stl`, `ring.stl`, `sphere.stl`, `wedge.stl` are all my own creations and subject to the terms of the license of this repository.

# Planned Updates
- Improvements to orientation optimization tool
- Simple graphical user interface for analysis
- Improved documentation
- Example visualizations
