import paraview.simple as ps
from pathlib import PurePath, Path
import re
import math


class Canvas:
    """Creates and Manages pipeline objects."""

    def __init__(self, view, output_files):
        self._output_files = output_files
        self._view = view

    def load_stl(self, name, color=[]):
        EXT = ".stl"
        stl_file = self._output_files.build_path(suffix=name, extension=EXT)
        return self._load_stl_file(stl_file, color)

    def load_stl_batch(self, name, colors=[]):
        EXT = ".stl"
        stl_files = self._output_files.build_batch_paths(suffix=name, extension=EXT)
        stls = []
        displays = []
        for i, f in enumerate(stl_files):
            stls[i], displays[i] = self._load_stl_file(f, next(colors))
        return stls, displays

    def load_segment_volume(self, name):
        EXT = ".vtk"
        vtk_file = self._output_files.build_path(suffix=name, extension=EXT)
        vtk = self._load_vtk_file(vtk_file)

        pass

    def _threshold_vtk(self, vtk, range):


    def _load_vtk_file(self, path):
        vtk = ps.LegacyVTKReader(FileNames=[path])

    def _load_stl_file(self, path, color=[]):
        stl = ps.STLReader(FileNames=[path])
        display = ps.Show(stl, self._view)
        if color:
            self._apply_solid_color(display, color)
        return stl, display

    def _apply_solid_color(self, display, color):
        display.AmbientColor = color
        display.DiffuseColor = color

    from pathlib import PurePath, Path


class OutputFiles:
    """Manages and loads output files."""

    _STL = PurePath(".stl")
    _VTK = PurePath(".vtk")

    def __init__(self, input_file_str, output_folder_str):
        input_file = PurePath(input_file_str)
        name = input_file.stem
        output_folder = PurePath(output_folder_str) / name

        self._name = name
        self._output_folder = output_folder

    def build_path(self, suffix="", extension=""):
        extension = self.fix_extension(extension)
        formatted = self._output_folder / self._format_name(suffix, extension)
        formatted = str(formatted).format(suffix=suffix, extension=extension)
        return PurePath(formatted)

    def build_batch_paths(self, suffix="", extension=""):
        extension = self.fix_extension(extension)
        suffix = suffix + "_*"
        glob = self.build_path(suffix=suffix, extension=extension)
        glob = PurePath(glob.name)
        glob = str(glob).format(suffix=suffix, extension=extension)
        files = list(Path(self._output_folder).glob(glob))

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


of = OutputFiles("steering_column_mount.stl", "C:/Users/wwarr/Desktop/a")
b = of.build_path("Parting", ".vtk")
print(b)

c = of.build_batch_paths("Feeders", ".stl")
print(c)
