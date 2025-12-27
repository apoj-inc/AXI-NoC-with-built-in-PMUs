"""
Local shim to provide cocotb_tools.pytest.plugin for pytest-cocotb while still
delegating everything else to the real cocotb_tools installation.
"""
from __future__ import annotations

import importlib.util
import sys
from pathlib import Path
from types import ModuleType


def _load_upstream_module(candidate: Path, name: str) -> ModuleType | None:
    """Load an upstream cocotb_tools.<name> from the given candidate path."""
    mod_path = candidate / f"{name}.py"
    if not mod_path.exists():
        return None
    full_name = f"cocotb_tools.{name}"
    if full_name in sys.modules:
        return sys.modules[full_name]

    spec = importlib.util.spec_from_file_location(full_name, mod_path)
    if spec and spec.loader:
        module = importlib.util.module_from_spec(spec)
        sys.modules[full_name] = module
        spec.loader.exec_module(module)
        return module
    return None


def _load_upstream_runner() -> None:
    """Load the real cocotb_tools modules from site-packages and register them."""
    this_dir = Path(__file__).resolve().parent

    for entry in sys.path[1:]:  # skip cwd which points here
        candidate = Path(entry) / "cocotb_tools"
        if candidate != this_dir and (candidate / "runner.py").exists():
            # allow normal package imports to find upstream modules
            if "__path__" in globals():
                __path__.append(str(candidate))  # type: ignore[name-defined]

            _load_upstream_module(candidate, "config")
            _load_upstream_module(candidate, "check_results")
            _load_upstream_module(candidate, "combine_results")
            _load_upstream_module(candidate, "sim_versions")
            _load_upstream_module(candidate, "_coverage")
            _load_upstream_module(candidate, "ipython_support")
            _load_upstream_module(candidate, "_vendor/distutils_version")
            _load_upstream_module(candidate, "runner")
            return
    raise ImportError(
        "cocotb_tools.runner not found. Install cocotb_tools in your environment."
    )


def _install_pytest_stub() -> None:
    """Provide cocotb_tools.pytest.plugin so pytest-cocotb import succeeds."""
    pkg_name = "cocotb_tools.pytest"
    mod_name = f"{pkg_name}.plugin"

    if mod_name in sys.modules:
        return

    if pkg_name not in sys.modules:
        pkg_mod = ModuleType(pkg_name)
        pkg_mod.__path__ = []  # type: ignore[attr-defined]
        sys.modules[pkg_name] = pkg_mod

    plugin_mod = ModuleType(mod_name)
    plugin_mod.__doc__ = (
        "Local stub plugin so pytest-cocotb can import "
        "cocotb_tools.pytest.plugin."
    )
    sys.modules[mod_name] = plugin_mod


_install_pytest_stub()
_load_upstream_runner()
