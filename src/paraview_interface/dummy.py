import argparse
import sys
import os
import json

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

ERR_BAD_SCRIPT_FOLDER = 2
script_folder = args.script_folder
if script_folder is None or not Path(script_folder).is_dir():
    print("No valid script folder supplied using -S option!")
    print("{:s}".format(str(script_folder)))
    sys.exit(ERR_BAD_SCRIPT_FOLDER)

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

sys.path.append(script_folder)
import cgt_objects

#### disable automatic camera reset on 'Show'
ps._DisableFirstRenderCameraReset()

# get active view
view = ps.GetActiveViewOrCreate("RenderView")
view.CameraParallelProjection = True
# view.ViewSize = [960, 720]

config = None
config_file = PurePath(args.script_folder) / "visualization_config.json"
with open(config_file) as f:
    config = json.load(f)
assert config is not None

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
