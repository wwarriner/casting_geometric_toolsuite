import argparse
import sys
import os

import paraview.simple as ps
from pathlib import PurePath, Path


def get_from_environment(arg):
    try:
        var = os.environ[arg]
        return var.replace('"', "")
    except:
        return None


parser = argparse.ArgumentParser()
parser.add_argument(
    "-S",
    "--script_folder",
    type=str,
    help="Folder location of scripts.",
    default=get_from_environment("script_folder"),
)
parser.add_argument(
    "-I",
    "--input_folder",
    type=str,
    help="Folder location of files to view.",
    default=get_from_environment("input_folder"),
)
parser.add_argument(
    "-n",
    "--name",
    type=str,
    help="Name of input to load.",
    default=get_from_environment("name"),
)
args = parser.parse_args()

script_folder = args.script_folder
if script_folder is None or not Path(script_folder).is_dir():
    print("No valid script folder supplied using -S option!")
    print("{:s}".format(str(script_folder)))

input_folder = args.input_folder
if input_folder is None or not Path(input_folder).is_dir():
    print("No valid input folder supplied using -I option!")
    print("{:s}".format(str(input_folder)))

name = args.name
if name is None:
    print("No valid name supplied using -n option!")
    print("{:s}".format(str(name)))

sys.path.append(script_folder)
from helpers import InputFiles, Canvas

#### disable automatic camera reset on 'Show'
ps._DisableFirstRenderCameraReset()

# get active view
view = ps.GetActiveViewOrCreate("RenderView")
view.CameraParallelProjection = True
# view.ViewSize = [960, 720]

files = InputFiles(name, input_folder)
cv = Canvas(view, files)
casting, casting_display = cv.load_stl("Casting")
casting_display.Opacity = 0.2

gprof_thold, gprof_display = cv.load_segment_volume(
    "filtered_GeometricProfile", [15, None]
)

# reset view to fit data
view.Update()
view.ResetCamera()
camera = view.GetActiveCamera()
camera.Roll(135)
camera.Elevation(-45)

# render
ps.Render()
# ps.Interact()
