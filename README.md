# AXI NoC with Built-in PMUs

SystemVerilog implementation of a configurable Network-on-Chip (NoC) with AXI-Stream based router datapaths, multiple topologies, cocotb simulation flow, and Quartus release packaging.

## Highlights

- Parametric router architecture with input buffering, arbitration, routing, and channel remapping.
- Topology support: `Mesh`, `Torus`, `Circulant`.
- Routing algorithm support: `XY`, `EWn_SNe`, `Clockwise` (depends on topology).
- Virtual channel and virtual network partitioning support.
- Optional simultaneous virtual-network routing mode.
- Cocotb + Questa simulation flow with reusable testbench layout.
- Quartus project/release generation under `release/*` and `build_system/quartus`.

## Repository Map

- `rtl/`: synthesizable RTL.
  - `rtl/router/`: router subsystem (main router, algorithm, arbiter, buffers, allocators, channel utilities).
  - `rtl/mesh`, `rtl/torus`, `rtl/circulant`: topology wrappers.
  - `rtl/axi`, `rtl/lib`, `rtl/cores`, `rtl/cosimulation`: infrastructure and integration modules.
- `tb/`: cocotb/SystemVerilog testbenches (`tb_<name>` layout).
- `doc/`: design diagrams and documentation assets (including Mermaid).
- `build_system/`: simulator and Quartus helper makefiles/scripts.
- `release/`: packaged source lists and Quartus project artifacts.
- `sw/`: software-side drivers and userland support.
- `utils/`: TCL/Python/Bash utilities.

## Quick Start

### Prerequisites

- Linux/WSL-like shell environment for `make` flow (`/bin/bash` is assumed in makefiles).
- Python 3 with venv support.
- Questa/ModelSim-compatible simulator for cocotb tests.
- Quartus Prime for FPGA compile/release targets.

### Run a cocotb test

Run default test:

```bash
make test
```

Run a specific testbench (example: mesh parallel):

```bash
make test GENERAL_TOPLEVEL=tb_mesh_parallel
```

Open waveform from previous cocotb run:

```bash
make wave GENERAL_TOPLEVEL=tb_mesh_parallel
```

Run pytest-oriented flow:

```bash
make run_pytest
```

### Quartus / Release flow

Compile with Quartus make wrapper:

```bash
make run_quartus TOPLEVEL=<top_module_name>
```

Create packaged releases:

```bash
make make_release
```

Clean release artifacts:

```bash
make clean_release
```

## Router Configuration Overview

Router implementation is centered in `rtl/router/src/router.sv` and configured via parameters for:

- AXI stream widths.
- Physical and virtual channel counts.
- Virtual network partition (`VIRTUAL_NETWORKS`).
- Buffering strategy (`BUFFER_ALLOCATOR`).
- Topology and routing algorithm selection.
- Coordinate model (`COORDINATES = "XY" | "N"`).

The router validates key constraints with assertions (channel-count consistency, virtual-network allocation, target width derivation).

For full details see [Router Documentation](rtl/router/README.md).

## Documentation Index

- Router subsystem docs:
  - [Router Main README](rtl/router/README.md)
  - [Router Source Docs](rtl/router/src/README.md)
- Mermaid router diagrams (canonical set):
  - [General Router Diagrams](doc/diagrams/mermaid/router/general)
  - [Internal Router Blocks](doc/diagrams/mermaid/router/internal)
  - [New router architecture/flow docs](doc/diagrams/mermaid/router)
- Topology diagrams:
  - [Mesh](doc/diagrams/drawio/svg/mesh.svg)
  - [Torus](doc/diagrams/drawio/svg/torus.svg)
  - [Circulant](doc/diagrams/drawio/svg/circulant.svg)

## Notes

- Deprecated modules are kept under `rtl/deprecated` and are not the primary implementation path.
- Some older diagram filenames use legacy spelling (`Simultanious`/`Simultainous`); docs in this refresh use corrected terminology in captions and references.
