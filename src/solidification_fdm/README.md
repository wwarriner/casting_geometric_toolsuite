# Solidification FDM Solver

A phase-change heat-transfer PDE solver written in MATLAB. The solver uses variable time-stepping based on a target maximum heat release. The target is a fraction of the latent heat of the material. If the material does not have a latent heat, or a sufficiently small latent heat, then the solver uses the sensible heat over the supplied freezing range instead. Time steps are determined using a bisection approach. The overall solver uses a preconditioned conjugate gradient with a modified incomplete Cholesky factorization preconditioner on a fully implicit, first-order stencil.

### Usage

Run `extend_search_path.m` to add the folder and subfolders to the MATLAB `path`. Navigate to the `testing` folder and run `test_case.m`. The test case is a cube-shaped melt inside a cube-shaped mold. The parameters are all adjustable, but before you adjust anything, try running it to make sure it operates properly. After some time you should see a figure window pop up which looks like the image below.

![Dashboard start.](https://github.com/wwarriner/solidification_fdm_solver/blob/master/doc/img/dashboard_start.png)

When the simulation has finished, the dashboard should look like the image below.

![Dashboard finish.](https://github.com/wwarriner/solidification_fdm_solver/blob/master/doc/img/dashboard_fin.png)

Additionally, a stacked bar chart showing the breakdown of computation time should pop up.

![Computation time breakdown.](https://github.com/wwarriner/solidification_fdm_solver/blob/master/doc/img/computation_time_breakdown.png)

The command window should look similar to the image below.

![Command window output example.](https://github.com/wwarriner/solidification_fdm_solver/blob/master/doc/img/command_window.png)

### The Dashboard

The upper-left three figures of the dashboard shows three one-dimensional profiles through the center of the mesh envelope. The upper profile is parallel to the X-axis, middle the Y-axis, and bottom the Z-axis. The upper-right figure of the dashboard shows a statistical distribution of temperatures over the melt as it changes with time. The X-axis is time, the Y-axis is temperature. The red dots show maximum temperature, green show mean temperature, and blue show minimum temperature. The bottom-left shows a histogram of temperature changes per time step over the entire mesh domain. The bottom-rigth is currently unused.
