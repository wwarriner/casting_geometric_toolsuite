import re
import math
from sys import float_info
from abc import ABC, abstractmethod
from pathlib import PurePath, Path
from itertools import takewhile

import paraview.simple as ps

# TODO need to expose .show()/.hide() methods so we can choose
class Visualization(ABC):
    def __init__(self, view, base_name):
        self._view = view
        self._base_name = base_name
        self._name = "Unknown"
        self._data = None
        self._display = None

    def change_alpha(self, alpha):
        assert self._display is not None
        try:
            self._display.Opacity = alpha
        except Exception as e:
            print("Could not change alpha of {}".format(self._name))
            print(e)

    def change_color(self, color):
        try:
            if isinstance(color, (list, tuple)):
                self._apply_solid_color(self._display, color)
            elif isinstance(color, str):
                color_map = self._get_color_map(color)
                self._apply_color_map(self._data, color_map)
            else:
                assert False
        except Exception as e:
            print("Could not change color of {}".format(self._name))
            print(e)

    @abstractmethod
    def load(self, file):
        assert False

    def _rename(self, name):
        assert self._data is not None
        try:
            ps.RenameSource(name, self._data)
            self._name = name
        except Exception as e:
            print("Could not rename to {}".format(name))
            print(e)

    def _visualize(self):
        assert self._data is not None
        self._display = ps.Show(self._data, self._view)

    def _get_color_map(self, color):
        if color.casefold() == "viridis".casefold():
            return "Viridis (matplotlib)"
        elif color.casefold() == "inferno".casefold():
            return "Inferno (matplotlib)"
        elif color.casefold() == "hue_L60".casefold():
            return "hue_L60"
        else:
            print("Warning: not able to identify color map {}".format(color))
            print("Using default colormap")
            return "Viridis (matplotlib)"

    @staticmethod
    def _apply_solid_color(display, color):
        assert len(color) == 3
        display.AmbientColor = color
        display.DiffuseColor = color

    @staticmethod
    def _apply_color_map(data, color_map):
        name = data.PointData.GetArray(0).Name
        color_lut = ps.GetColorTransferFunction(name)
        color_lut.ApplyPreset(color_map, True)

    def _get_postfix(self, path):
        return re.sub(self._base_name + "_", "", path.stem)


class Polygon(Visualization):
    def __init__(self, view, base_name):
        super().__init__(view, base_name)

    def load(self, path):
        data = ps.STLReader(FileNames=[str(path)])
        name = self._get_postfix(path)

        self._data = data
        self._rename(name)
        self._visualize()


class Polygons(Visualization):
    def __init__(self, view, base_name):
        super().__init__(view, base_name)
        self._polygons = None

    def load(self, files):
        assert self._polygons is None
        self._polygons = []
        for f in files:
            polygon = Polygon(self._view, self._base_name)
            polygon.load(f)
            self._polygons.append(polygon)

    def change_alpha(self, alpha):
        assert self._polygons is not None
        for p in self._polygons:
            p.change_alpha(alpha)

    def change_color(self, color):
        assert self._polygons is not None
        for p in self._polygons:
            p.change_color(color)

    @staticmethod
    def _format_names(name, count):
        return ["{name}_{index}".format(name=name, index=(i + 1)) for i in range(count)]


class Volume(Visualization):
    def __init__(self, view, base_name):
        super().__init__(view, base_name)

    def load(self, path):
        vtk = ps.LegacyVTKReader(FileNames=[str(path)])
        name = self._get_postfix(path)
        data = self._threshold_vtk(vtk, name)

        self._data = data
        self._rename(name)
        self._visualize()

    def apply_range(self, in_range):
        assert self._data is not None
        try:
            data_range = self._get_range(self._data)
        except Exception:
            data_range = (0.0, 0.0)

        out_range = [0.0, 0.0]
        flexible = [False, False]
        for i, r in enumerate(in_range):
            if r == "min":
                val = data_range[0]
            elif r == "max":
                val = data_range[1]
            elif r is None:
                val = data_range[i]
                flexible[i] = True
            elif r in ["+eps", "eps"]:
                val = float_info.epsilon
                flexible[i] = True
            elif r == "-eps":
                val = -float_info.epsilon
                flexible[i] = True
            else:
                val = in_range[i]
                flexible[i] = True
            out_range[i] = val
        if out_range[1] < out_range[0]:
            if flexible[0] and flexible[1]:
                mean = sum(out_range) / len(out_range)
                out_range = [mean, mean]
            elif flexible[0]:
                out_range[0] = out_range[1]
            else:
                out_range[1] = out_range[0]
        self._data.ThresholdRange = out_range

    def _threshold_vtk(self, vtk, name):
        threshold = ps.Threshold(Input=vtk)
        threshold.Scalars = ["POINTS", name]
        threshold.ThresholdRange = self._get_range(vtk)
        return threshold

    @staticmethod
    def _get_range(data):
        return data.PointData.GetArray(0).GetRange()


class InputFiles:
    """Manages and loads output files."""

    def __init__(self, input_folder_str):
        self._input_folder = PurePath(input_folder_str)

    def exists(self, postfix="", extension=""):
        path = self.build_path(postfix, extension)
        return Path(path).is_file()

    def build_path(self, postfix="", extension=""):
        extension = self._fix_extension(extension)
        formatted = self._input_folder / self._format_name(postfix, extension)
        formatted = str(formatted).format(postfix=postfix, extension=extension)
        return PurePath(formatted)

    def build_batch_paths(self, postfix="", extension=""):
        extension = self._fix_extension(extension)
        postfix = postfix + "_*"
        glob = self.build_path(postfix=postfix, extension=extension)
        glob = PurePath(glob.name)
        glob = str(glob).format(postfix=postfix, extension=extension)
        files = list(Path(self._input_folder).glob(glob))

        expr = r"^.*?([0-9]+).*?$"
        r = re.compile(expr, re.IGNORECASE)
        files = [f for f in files if self._is_valid_batch_file(r, f)]
        return files

    def get_base_name(self):
        glob = "*.*"
        files = list(Path(self._input_folder).glob(glob))
        files = [str(x) for x in files]
        lcp = self._longest_common_prefix(*files)
        return str(PurePath(lcp).stem).strip("_")

    @staticmethod
    def _longest_common_prefix(*strings):
        return "".join(
            ch[0] for ch in takewhile(lambda x: min(x) == max(x), zip(*strings))
        )

    def _format_name(self, postfix="", extension=""):
        formatted = self.get_base_name()
        if postfix:
            formatted = formatted + "_{postfix}"
        if extension:
            formatted = formatted + ".{extension}"
        return formatted

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

    @staticmethod
    def _fix_extension(extension):
        return extension.lstrip(".")


# TODO This code feels inverted, a lot of this can probably be offloaded to the
# TODO subclasses or input_files


class Visuals:
    """Builds visuals from concrete Object subclasses. The input_files argument
    allows construction of file paths from names. Names come from the config
    object, which is a JSON object."""

    _STL = "stl".casefold()
    _VTK = "vtk".casefold()
    _SINGLE = "single".casefold()
    _CATEGORICAL = "categorical".casefold()
    _CONTINUOUS = "continuous".casefold()

    _ALPHA = "alpha"
    _COLOR = "color"
    _RANGE = "range"

    def __init__(self, view, config, input_files):
        self._strategies = self._build_strategies()
        for process, config_item in config["processes"].items():
            if not self._exists(process, config_item, input_files):
                continue
            strategy = self._get_strategy(config_item)
            strategy(view, process, config_item, input_files)

    def _load_single_stl(self, view, process, config, input_files):
        base_name = input_files.get_base_name()
        path = self._get_path(process, config, input_files)
        self._create_polygon(view, base_name, path, config)

    def _load_categorical_stl(self, view, process, config, input_files):
        base_name = input_files.get_base_name()
        paths = self._get_paths(process, config, input_files)
        self._create_polygons(view, base_name, paths, config)

    def _load_continuous_stl(self, view, process, config, input_files):
        raise NotImplementedError

    def _load_single_vtk(self, view, process, config, input_files):
        base_name = input_files.get_base_name()
        path = self._get_path(process, config, input_files)
        self._create_volume(view, base_name, path, config, [1, 1])

    def _load_categorical_vtk(self, view, process, config, input_files):
        base_name = input_files.get_base_name()
        path = self._get_path(process, config, input_files)
        self._create_volume(view, base_name, path, config, [1, "max"])

    def _load_continuous_vtk(self, view, process, config, input_files):
        base_name = input_files.get_base_name()
        path = self._get_path(process, config, input_files)
        self._create_volume(view, base_name, path, config, ["min", "max"])

    def _create_polygon(self, view, base_name, path, config):
        p = Polygon(view, base_name)
        p.load(path)
        self._update_alpha(config, p)
        self._update_color(config, p)

    def _create_polygons(self, view, base_name, paths, config):
        p = Polygons(view, base_name)
        p.load(paths)
        self._update_alpha(config, p)
        self._update_color(config, p)

    def _create_volume(self, view, base_name, path, config, default_range):
        v = Volume(view, base_name)
        v.load(path)
        self._update_alpha(config, v)
        self._update_color(config, v)
        self._update_range(config, v, default_range)

    def _get_strategy(self, config):
        return self._strategies[self._get_format(config)][self._get_type(config)]

    def _exists(self, process, config, input_files):
        return input_files.exists(postfix=process, extension=self._get_format(config))

    def _get_path(self, process, config, input_files):
        return input_files.build_path(
            postfix=process, extension=self._get_format(config)
        )

    def _get_paths(self, process, config, input_files):
        return input_files.build_batch_paths(
            postfix=process, extension=self._get_format(config)
        )

    def _get_format(self, config):
        return config["data"]["format"].casefold()

    def _get_type(self, config):
        return config["data"]["type"].casefold()

    def _build_strategies(self):
        return {
            self._STL: {
                self._SINGLE: self._load_single_stl,
                self._CATEGORICAL: self._load_categorical_stl,
                self._CONTINUOUS: self._load_continuous_stl,
            },
            self._VTK: {
                self._SINGLE: self._load_single_vtk,
                self._CATEGORICAL: self._load_categorical_vtk,
                self._CONTINUOUS: self._load_categorical_vtk,
            },
        }

    def _update_alpha(self, config, visualization):
        alpha = 1.0
        if self._ALPHA in config:
            alpha = config[self._ALPHA]
        if alpha is not None:
            visualization.change_alpha(alpha)

    def _update_color(self, config, visualization):
        color = [1.0, 1.0, 1.0]
        if self._COLOR in config:
            color = config[self._COLOR]
        if color is not None:
            visualization.change_color(color)

    def _update_range(self, config, visualization, default_range=["min", "max"]):
        r = default_range
        if self._RANGE in config:
            r = config[self._RANGE]
        if r is not None:
            visualization.apply_range(r)
