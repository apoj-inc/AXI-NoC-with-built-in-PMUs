# Router Subsystem Documentation

This directory contains the configurable AXI-Stream router used by topology wrappers in this repository.

- Main module: `rtl/router/src/router.sv`
- Supporting modules: `rtl/router/src/*`
- Shared helper macros: `rtl/router/inc/*`

Back to project root: [README](../../README.md)

## Architecture

The nominal data/control flow is:

1. `s_axis_i[CHANNEL_NUMBER]` enters `router_buffer`.
2. `router_buffer` applies allocator policy and per-channel FIFOs.
3. `arbiter` selects one active input stream and outputs the selected target information.
4. `algorithm` computes the output port from router coordinates/topology/algorithm.
5. Stream is emitted through `m_axis_o[CHANNEL_NUMBER]`.

When `SIMULTANIOUS_VIRTUAL_NETWORK_ROUTING=1`, routing is split by virtual network and each VN gets its own `arbiter + algorithm` path before being remapped back to full channel space.

## Virtual Channels and Virtual Networks

- `PHYSICAL_CHANNEL_NUMBER`: count of physical router ports (for example Home/N/E/S/W).
- `VIRTUAL_CHANNEL_NUMBER`: VCs per physical channel.
- `CHANNEL_NUMBER = PHYSICAL_CHANNEL_NUMBER * VIRTUAL_CHANNEL_NUMBER`.
- `VIRTUAL_NETWORK_NUMBER`: number of VN partitions.
- `VIRTUAL_NETWORKS[]`: number of VCs assigned to each VN.

Required invariant:

- `sum(VIRTUAL_NETWORKS[i]) == VIRTUAL_CHANNEL_NUMBER`

The router checks this in an initialization-time assertion.

## Configuration Interface (router.sv)

### AXIS widths

- `AXIS_DATA_WIDTH`
- `AXIS_ID_WIDTH`
- `AXIS_DEST_WIDTH`
- `AXIS_USER_WIDTH`

### Channel topology

- `PHYSICAL_CHANNEL_NUMBER`
- `PHYSICAL_CHANNEL_NUMBER_WIDTH`
- `VIRTUAL_CHANNEL_NUMBER`
- `CHANNEL_NUMBER`
- `CHANNEL_NUMBER_WIDTH`

### Virtual network routing mode

- `SIMULTANIOUS_VIRTUAL_NETWORK_ROUTING`
- `VIRTUAL_NETWORK_NUMBER`
- `VIRTUAL_NETWORKS[]`

### Buffering

- `BUFFER_DEPTH`
- `BUFFER_ALLOCATOR = "Straight" | "KeepInNetwork"`

### Routing choices

- `TOPOLOGY = "Mesh" | "Torus" | "Circulant"`
- `ALGORITHM`:
  - Mesh: `XY`
  - Torus: `XY` or `EWn_SNe`
  - Circulant: `Clockwise`
- `COORDINATES = "XY" | "N"`

### Mesh/Torus coordinates

- `MAX_ROUTERS_X`, `MAX_ROUTERS_X_WIDTH`
- `MAX_ROUTERS_Y`, `MAX_ROUTERS_Y_WIDTH`
- `ROUTER_X`, `ROUTER_Y`

### Circulant coordinates

- `ROUTER_N`
- `ROUTERS_COUNT`
- `GENERATICS_COUNT`
- `GENERATICS[]`

## Derived Target Width (`TARGET_LEN`)

`router.sv` derives internal `TARGET_LEN` as:

- `COORDINATES == "XY"`: `MAX_ROUTERS_X_WIDTH + MAX_ROUTERS_Y_WIDTH`
- `COORDINATES == "N"`: `$clog2(ROUTERS_COUNT)`

If no valid coordinate mode is selected, `TARGET_LEN` becomes zero and the module emits an assertion error.

## Assertions and Constraints

`router.sv` validates at elaboration/simulation start:

- `TARGET_LEN != 0`
- `CHANNEL_NUMBER == PHYSICAL_CHANNEL_NUMBER * VIRTUAL_CHANNEL_NUMBER`
- `sum(VIRTUAL_NETWORKS) == VIRTUAL_CHANNEL_NUMBER`

`algorithm.sv` also emits errors if an invalid `TOPOLOGY`/`ALGORITHM` pair is selected.

## Mermaid Diagrams

Canonical existing diagrams:

- General router mode diagrams:
  - `doc/diagrams/mermaid/router/general/RouterNonSimultainous.md`
  - `doc/diagrams/mermaid/router/general/RouterSimultanious.md`
- Internal blocks:
  - `doc/diagrams/mermaid/router/internal/*`

New documentation diagrams added in this refresh:

- `doc/diagrams/mermaid/router/RouterVirtualNetworkFlow.md`
- `doc/diagrams/mermaid/router/RouterParameterDependencies.md`
- `doc/diagrams/mermaid/router/RouterAlgorithmSelectorDecision.md`

## Source-Level Module Guide

Detailed module notes are in [src/README.md](src/README.md).
