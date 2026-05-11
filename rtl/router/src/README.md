# Router Source Modules

This file documents `rtl/router/src` modules by subsystem.

## Top-Level Modules

### `router.sv`

Top integration module:

- Instantiates `router_buffer`, then either:
  - single `arbiter + algorithm` path, or
  - per-VN `arbiter + algorithm` paths with `network_channel_demux/mux` and `network_channel_narrower`.
- Derives `TARGET_LEN` from `COORDINATES`.
- Validates configuration invariants with assertions.

### `router_buffer.sv`

Ingress buffering layer:

- Applies allocator policy:
  - `buffer_allocator_straight` (fixed channel mapping)
  - `buffer_allocator_keep_in_network` (dynamic in-network assignment within VN scope)
- Instantiates one `stream_fifo` per channel (`BUFFER_DEPTH`).

### `arbiter.sv`

Single-output stream arbiter over multiple channels:

- Maintains `current_grant_o`.
- Exposes `target_o` extracted from routing header payload.
- Optional policy pinning with `WAIT_FOR_TLAST`.

### `algorithm.sv`

Routing decision and output-channel selection:

- Decodes current input channel to `(physical, virtual)` via `channel_decoder`.
- Selects physical output via algorithm selector module.
- Re-encodes chosen physical + preserved virtual channel via `channel_encoder`.
- Tracks `busy` state to protect routing-header-driven flow ownership until TLAST.

## Algorithm Selectors

- `algorithm_selectors/mesh/algorithm_selector_mesh_XY.sv`
  - Deterministic XY path: X dimension first, then Y.
- `algorithm_selectors/torus/algorithm_selector_torus_XY.sv`
  - XY adapted for torus wrapping.
- `algorithm_selectors/torus/algorithm_selector_torus_EWn_SNe.sv`
  - Enhanced torus policy with arc and incoming-channel-aware rules.
- `algorithm_selectors/torus/algorithm_selector_torus_XY_one_way.sv`
  - One-way torus variant.
- `algorithm_selectors/circulant/algorithm_selector_clockwise.sv`
  - Step-based clockwise policy using `GENERATICS[]`.

## Buffer Allocators

- `buffer_allocators/buffer_allocator_straight.sv`
  - Pure pass-through channel identity mapping.
- `buffer_allocators/buffer_allocator_keep_in_network.sv`
  - Per-physical/per-VN dynamic target allocation with occupancy tracking.

## Channel Utility Blocks

- `utils/channel_encoder.sv`
  - `(physical_channel, virtual_channel) -> flat channel index`.
- `utils/channel_decoder.sv`
  - `flat channel index -> (physical_channel, virtual_channel)`.
- `utils/network_channel_demux.sv`
  - Splits flat channel array into per-VN channel arrays.
- `utils/network_channel_mux.sv`
  - Merges per-VN channel arrays back into flat channel array.
- `utils/network_channel_narrower.sv`
  - Width adapter for array-of-interface slices (keeps first `min(WIDTH_IN, WIDTH_OUT)` channels).

## Queue Implementations

- `queue/blind_queue.sv`
- `queue/signalled_queue.sv`

Both define `module queue`, and represent alternative queue semantics for experiments/legacy variants. Current top-level buffer path uses `stream_fifo` through `router_buffer.sv`.

## Integration Notes

- Expected include files/macros:
  - `defines.svh`
  - `axis_defines.svh`
  - `axi2axis_typedef.svh` (where required)
  - `virtual_networks_utils.svh`
  - `virtual_channels_utils.svh`
- `TOPOLOGY`, `ALGORITHM`, and `COORDINATES` must be set to compatible combinations.
- `VIRTUAL_NETWORKS[]` partition must be consistent with `VIRTUAL_CHANNEL_NUMBER`.
