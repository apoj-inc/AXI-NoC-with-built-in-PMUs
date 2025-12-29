import shutil, glob
from os import environ, makedirs, path
from shutil import copytree

import pytest
from cocotb_tools.runner import get_runner

VERILOG_SOURCES   = environ['VERILOG_SOURCES'].strip().split(' ')
INCLUDE_DIRS      = environ['INCLUDE_DIRS'].strip().split(' ')
COCOTB_TESTS_DIRS = environ['TESTS_DIRS'].strip().split(' ')
BUILD_DIR         = environ['BUILD_DIR']
LOGS_DIR          = environ['LOGS_DIR']
RESULTS_DIR       = environ['RESULTS_DIR']

def _have_questa() -> bool:
    return shutil.which('vsim') is not None or shutil.which('qrun') is not None


@pytest.mark.skipif(not _have_questa(), reason='Questa not available in PATH')
@pytest.mark.parametrize('cocotb_test_dir', COCOTB_TESTS_DIRS)
def test_cocotb(cocotb_test_dir) -> None:
    runner = get_runner('questa')

    test_dir = BUILD_DIR
    makedirs(test_dir, exist_ok=True)
    makedirs(LOGS_DIR, exist_ok=True)
    makedirs(RESULTS_DIR, exist_ok=True)

    copytree(cocotb_test_dir, test_dir, dirs_exist_ok=True)

    hdl_toplevel = path.basename(glob.glob('tb_*.sv', root_dir=cocotb_test_dir)[0]).split('.')[0]
    test_module = path.basename(glob.glob('tb_*.py', root_dir=cocotb_test_dir)[0]).split('.')[0]

    runner.build(
        hdl_library='work',
        sources=VERILOG_SOURCES,
        includes=INCLUDE_DIRS,
        hdl_toplevel=hdl_toplevel,
        build_dir=test_dir,
        waves=False,
    )

    runner.test(
        hdl_toplevel_library='work',
        test_module=test_module,
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang='verilog',
        build_dir=test_dir,
        test_dir=test_dir,
        waves=False,
        log_file=LOGS_DIR+f'/{test_module}.log',
        results_xml=RESULTS_DIR+f'/{test_module}.xml'
    )
