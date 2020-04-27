import argparse
import sys
import os
import json

import paraview.simple as ps
from pathlib import PurePath, Path


def get_from_environment(arg):
    try:
        var = os.environ[arg]
        var = var.replace('"', "")
        return var.strip()
    except:
        return None


parser = argparse.ArgumentParser()
parser.add_argument(
    "-S",
    "--interface_folder",
    type=str,
    help="Folder location of python interface.",
    default=get_from_environment("interface_folder"),
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

ERR_BAD_INTERFACE_FOLDER = 2
interface_folder = args.interface_folder
if interface_folder is None or not Path(interface_folder).is_dir():
    print("No valid script folder supplied using -S option!")
    print("{:s}".format(str(interface_folder)))
    sys.exit(ERR_BAD_INTERFACE_FOLDER)

ERR_BAD_INPUT_FOLDER = 3
input_folder = args.input_folder
if input_folder is None or not Path(input_folder).is_dir():
    print("No valid input folder supplied using -I option!")
    print("{:s}".format(str(input_folder)))
    sys.exit(ERR_BAD_INPUT_FOLDER)

ERR_BAD_NAME = 4
name = args.name
if name is None:
    print("No valid name supplied using -n option!")
    print("{:s}".format(str(name)))
    sys.exit(ERR_BAD_NAME)

sys.path.append(interface_folder)
import cgt_objects

config = None
config_file = PurePath(args.interface_folder) / "visualization_config.json"
with open(config_file) as f:
    config = json.load(f)
assert config is not None

#### disable automatic camera reset on 'Show'
ps._DisableFirstRenderCameraReset()

# get active view
view = ps.GetActiveViewOrCreate("RenderView")
view.CameraParallelProjection = True
# view.ViewSize = [960, 720]

input_files = cgt_objects.InputFiles(PurePath(args.input_folder))
visuals = cgt_objects.Visuals(view, config, input_files)

# pseudocode
# determine load strategy
#  try .data
#  fail? try extension
#  fail? go to next object
# try load object
#  fail? go to next object
# determine vis strategy
#  use combination of .data and .type
# apply vis strategy to loaded object

# reset view to fit data
view.Update()
view.ResetCamera()
camera = view.GetActiveCamera()
camera.Roll(135)
camera.Elevation(-45)

# render
ps.Render()
# ps.Interact()
