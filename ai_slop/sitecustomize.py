"""
Local sitecustomize shim to keep pytest-cocotb from failing on import when
`cocotb_tools.pytest.plugin` is missing in the installed cocotb_tools package.

This simply pre-registers an empty module under that name so pytest can load the
plugin entrypoint without crashing; actual cocotb tests are driven explicitly
from pytest via cocotb_tools.runner.
"""
import sys
import types


def _install_pytest_stub() -> None:
    pkg_name = "cocotb_tools.pytest"
    mod_name = f"{pkg_name}.plugin"

    if mod_name in sys.modules:
        return

    try:
        import cocotb_tools  # noqa: F401
    except Exception:
        return

    if pkg_name not in sys.modules:
        pkg_mod = types.ModuleType(pkg_name)
        pkg_mod.__path__ = []
        sys.modules[pkg_name] = pkg_mod

    plugin_mod = types.ModuleType(mod_name)
    plugin_mod.__doc__ = (
        "Local stub plugin so pytest-cocotb can import "
        "cocotb_tools.pytest.plugin."
    )
    sys.modules[mod_name] = plugin_mod


_install_pytest_stub()
