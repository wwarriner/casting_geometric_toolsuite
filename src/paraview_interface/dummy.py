import paraview.simple as ps
from pathlib import PurePath
from helpers import OutputFiles

# trace generated using paraview version 5.7.0
#
# To ensure correct image size when batch processing, please search
# for and uncomment the line `# renderView*.ViewSize = [*,*]`

#### import the simple module from the paraview
# from paraview.simple import *

#### disable automatic camera reset on 'Show'
ps._DisableFirstRenderCameraReset()

# get active view
view = ps.GetActiveViewOrCreate("RenderView")

# create a new 'STL Reader'
input_file = "steering_column_mount.stl"
output_folder = "C:\\Users\\wwarr\\Desktop\\a"
of = OutputFiles(input_file, output_folder)
stl_file = of.build_with_suffix(".stl", "Casting")
casting_stl = ps.STLReader(FileNames=[str(stl_file)])

# show data in view
casting_display = ps.Show(casting_stl, view)
casting_display.Opacity = 0.2

# reset view to fit data
view.Update()
view.ResetCamera()
camera = view.GetActiveCamera()
camera.Roll(135)
camera.Elevation(-45)

# render
ps.Render()
