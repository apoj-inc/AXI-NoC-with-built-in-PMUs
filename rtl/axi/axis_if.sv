`include "defines.svh"

interface axis_if #(
    parameter AXIS_DATA_WIDTH = 40,
    parameter AXIS_ID_WIDTH   = 4,
    parameter AXIS_DEST_WIDTH = 4,
    parameter AXIS_USER_WIDTH = 4
) ();

    // T channel 
    logic                           TVALID ;
    logic                           TREADY ;
    logic [AXIS_DATA_WIDTH-1:0]     TDATA  ;
    logic [(AXIS_DATA_WIDTH/8)-1:0] TSTRB  ;
    logic [(AXIS_DATA_WIDTH/8)-1:0] TKEEP  ;
    logic                           TLAST  ;
    logic [AXIS_ID_WIDTH-1:0]       TID    ;
    logic [AXIS_DEST_WIDTH-1:0]     TDEST  ;
    logic [AXIS_USER_WIDTH-1:0]     TUSER  ;

    modport m (
        output TVALID,
        input  TREADY,
        output TDATA, TSTRB, TKEEP, TLAST, TID, TDEST, TUSER
    );

    modport s (
        input  TVALID,
        output TREADY,
        input  TDATA, TSTRB, TKEEP, TLAST, TID, TDEST, TUSER
    );
    
endinterface
