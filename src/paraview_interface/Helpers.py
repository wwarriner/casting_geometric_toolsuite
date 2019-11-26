import paraview.simple as ps
from pathlib import PurePath, Path
import re
import math


class Canvas:
    """Creates and Manages pipeline objects."""

    def __init__(self, view, input_files):
        self._input_files = input_files
        self._view = view

    def load_stl(self, name, color=None):
        EXT = ".stl"
        stl_file = self._input_files.build_path(suffix=name, extension=EXT)
        return self._load_stl_file(stl_file, color)

    def load_stl_batch(self, name, colors=[None]):
        EXT = ".stl"
        stl_files = self._input_files.build_batch_paths(suffix=name, extension=EXT)
        stls = []
        displays = []
        for i, f in enumerate(stl_files):
            stls[i], displays[i] = self._load_stl_file(f, next(colors))
        return stls, displays

    def load_segment_volume(self, name, threshold_range=None, color=None):
        EXT = ".vtk"
        vtk_file = self._input_files.build_path(suffix=name, extension=EXT)
        vtk = self._load_vtk_file(vtk_file)
        return self._threshold_vtk(vtk, name, threshold_range)

    def _threshold_vtk(self, vtk, scalars, threshold_range=None, color=None):
        threshold = ps.Threshold(Input=vtk)
        threshold.Scalars = ["POINTS", scalars]
        if threshold_range is not None:
            initial_range = threshold.ThresholdRange
            if threshold_range[0] is None:
                threshold_range[0] = -1e300
            if threshold_range[1] is None:
                threshold_range[1] = 1e300
            threshold.ThresholdRange = threshold_range
        display = ps.Show(threshold, self._view)
        return threshold, display

    def _load_vtk_file(self, path):
        vtk = ps.LegacyVTKReader(FileNames=[str(path)])
        return vtk

    def _load_stl_file(self, path, color=None):
        stl = ps.STLReader(FileNames=[str(path)])
        display = ps.Show(stl, self._view)
        if color is not None:
            self._apply_solid_color(display, color)
        return stl, display

    def _apply_solid_color(self, display, color):
        display.AmbientColor = color
        display.DiffuseColor = color

    from pathlib import PurePath, Path


class InputFiles:
    """Manages and loads output files."""

    _STL = PurePath(".stl")
    _VTK = PurePath(".vtk")

    def __init__(self, name, input_folder_str):
        input_folder = PurePath(input_folder_str)

        self._name = name
        self._input_folder = input_folder

    def build_path(self, suffix="", extension=""):
        extension = self.fix_extension(extension)
        formatted = self._input_folder / self._format_name(suffix, extension)
        formatted = str(formatted).format(suffix=suffix, extension=extension)
        return PurePath(formatted)

    def build_batch_paths(self, suffix="", extension=""):
        extension = self.fix_extension(extension)
        suffix = suffix + "_*"
        glob = self.build_path(suffix=suffix, extension=extension)
        glob = PurePath(glob.name)
        glob = str(glob).format(suffix=suffix, extension=extension)
        files = list(Path(self._input_folder).glob(glob))

        expr = r"^.*?([0-9]+).*?$"
        r = re.compile(expr, re.IGNORECASE)
        files = [f for f in files if self._is_valid_batch_file(r, f)]
        return files

    @staticmethod
    def _is_valid_batch_file(compiled_expr, batch_file):
        if not batch_file.is_file():
            return False

        match = compiled_expr.match(str(batch_file))
        if match.lastindex <= 0:
            return False

        value = float(match.group(1))
        if math.isnan(value) or math.isinf(value) or value < 0.0:
            return False

        return True

    def _format_name(self, suffix="", extension=""):
        formatted = self._name
        if suffix:
            formatted = formatted + "_{suffix}"
        if extension:
            formatted = formatted + ".{extension}"
        return formatted

    @staticmethod
    def fix_extension(extension):
        return extension.lstrip(".")
