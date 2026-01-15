`ifndef AXIS_TYPE_TEST_SVH
`define AXIS_TYPE_TEST_SVH

`include "defines.svh"

parameter AXIS_DATA_WIDTH = 32;
`ifdef TID_PRESENT
parameter ID_WIDTH = 8;
`endif
`ifdef TDEST_PRESENT
parameter DEST_WIDTH = 8;
`endif
`ifdef TUSER_PRESENT
parameter USER_WIDTH   = 4;
`endif

`include "axis_type.svh"

`endif
