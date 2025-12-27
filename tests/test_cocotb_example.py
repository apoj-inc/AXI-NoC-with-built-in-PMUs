from pathlib import Path
import shutil
from os import environ

import pytest
from cocotb_tools.runner import get_runner


REPO_ROOT = Path(__file__).resolve().parents[1]
RTL_LIST = REPO_ROOT / "rtl/lists/files_rtl.lst"

VERILOG_SOURCES = environ['VERILOG_SOURCES']
INCLUDE_DIRS    = environ['INCLUDE_DIRS']


def _have_questa() -> bool:
    return shutil.which("vsim") is not None or shutil.which("qrun") is not None


@pytest.mark.skipif(not _have_questa(), reason="Questa not available in PATH")
def test_uart_loop_with_questa(tmp_path: Path) -> None:
    runner = get_runner("questa")

    rtl_sources = [
        REPO_ROOT / line.strip()
        for line in RTL_LIST.read_text().splitlines()
        if line.strip()
    ]

    tb_dir = REPO_ROOT / "tb" / "tb_example"
    tb_sources = [tb_dir / "uart_loop.sv", tb_dir / "uart_rx.sv", tb_dir / "uart_tx.sv"]

    build_dir = tmp_path / "sim_build"
    runner.build(
        sources=VERILOG_SOURCES,
        includes=INCLUDE_DIRS,
        hdl_toplevel="uart_loop",
        build_dir=build_dir,
        waves=False,
    )

    env = {
        "COCOTB_LIBRARY_COVERAGE": "1",
        "COCOTB_USER_COVERAGE": "1",
        "COCOTB_RESULTS_FILE": str(tmp_path / "results.xml"),
    }

    runner.test(
        test_module="tb.tb_example.tb_example",
        hdl_toplevel="uart_loop",
        hdl_toplevel_lang="verilog",
        build_dir=build_dir,
        test_dir=tmp_path,
        waves=False,
        extra_env=env,
    )
