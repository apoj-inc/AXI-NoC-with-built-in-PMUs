from pathlib import Path
import shutil
from os import environ, makedirs
from shutil import copytree

import pytest
from cocotb_tools.runner import get_runner


REPO_ROOT = Path(__file__).resolve().parents[1]
RTL_LIST = REPO_ROOT / 'rtl/lists/files_rtl.lst'

VERILOG_SOURCES = environ['VERILOG_SOURCES'].strip().split(' ')
INCLUDE_DIRS    = environ['INCLUDE_DIRS'].strip().split(' ')
BUILD_DIR       = environ['BUILD_DIR']

def _have_questa() -> bool:
    return shutil.which('vsim') is not None or shutil.which('qrun') is not None


@pytest.mark.skipif(not _have_questa(), reason='Questa not available in PATH')
def test_uart_loop_with_questa() -> None:
    runner = get_runner('questa')

    test_dir = BUILD_DIR+'/tb_example'
    makedirs(test_dir, exist_ok=True)

    copytree('tb/tb_example', test_dir, dirs_exist_ok=True)

    env = {
        'COCOTB_LIBRARY_COVERAGE': '1',
        'COCOTB_USER_COVERAGE': '1',
        'COCOTB_RESULTS_FILE': BUILD_DIR+'/results.xml',
    }

    runner.build(
        hdl_library='work',
        sources=VERILOG_SOURCES,
        includes=INCLUDE_DIRS,
        hdl_toplevel='uart_loop',
        build_dir=test_dir,
        waves=False,
    )

    runner.test(
        hdl_toplevel_library='work',
        test_module='tb_example',
        hdl_toplevel='uart_loop',
        hdl_toplevel_lang='verilog',
        build_dir=test_dir,
        test_dir=test_dir,
        waves=False,
        extra_env=env,
    )
