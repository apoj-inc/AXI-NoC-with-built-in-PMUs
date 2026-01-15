`include "defines.svh"

interface axis_if #(
    parameter AXIS_DATA_WIDTH = 32
    `ifdef TID_PRESENT
    ,
    parameter ID_WIDTH = 4
    `endif
    `ifdef TDEST_PRESENT
    ,
    parameter DEST_WIDTH = 4
    `endif
    `ifdef TUSER_PRESENT
    ,
    parameter USER_WIDTH = 4
    `endif
) ();

    // T channel 
    logic TVALID;
    logic TREADY;
    logic [AXIS_DATA_WIDTH-1:0] TDATA;
    
    `ifdef TSTRB_PRESENT
    logic [(AXIS_DATA_WIDTH/8)-1:0] TSTRB;
    `endif
    `ifdef TKEEP_PRESENT
    logic [(AXIS_DATA_WIDTH/8)-1:0] TKEEP;
    `endif
    `ifdef TLAST_PRESENT
    logic TLAST;
    `endif
    `ifdef TID_PRESENT
    logic [ID_WIDTH-1:0] TID;
    `endif
    `ifdef TDEST_PRESENT
    logic [DEST_WIDTH-1:0] TDEST;
    `endif
    `ifdef TUSER_PRESENT
    logic [USER_WIDTH-1:0] TUSER;
    `endif

    modport m (
        output TVALID,
        input TREADY,
        output TDATA

        `ifdef TSTRB_PRESENT
        , TSTRB
        `endif
        `ifdef TKEEP_PRESENT
        , TKEEP
        `endif
        `ifdef TLAST_PRESENT
        , TLAST
        `endif
        `ifdef TID_PRESENT
        , TID
        `endif
        `ifdef TDEST_PRESENT
        , TDEST
        `endif
        `ifdef TUSER_PRESENT
        , TUSER
        `endif
    );

    modport s (
        input TVALID,
        output TREADY,
        input TDATA

        `ifdef TSTRB_PRESENT
        , TSTRB
        `endif
        `ifdef TKEEP_PRESENT
        , TKEEP
        `endif
        `ifdef TLAST_PRESENT
        , TLAST
        `endif
        `ifdef TID_PRESENT
        , TID
        `endif
        `ifdef TDEST_PRESENT
        , TDEST
        `endif
        `ifdef TUSER_PRESENT
        , TUSER
        `endif
    );
    
endinterface
