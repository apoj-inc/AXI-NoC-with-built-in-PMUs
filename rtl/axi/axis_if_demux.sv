`include "defines.svh"

module axis_if_demux #(
    parameter CHANNEL_NUMBER = 5,
    parameter CHANNEL_NUMBER_WIDTH = $clog2(CHANNEL_NUMBER),
    parameter AXIS_DATA_WIDTH = 40
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
) (
    axis_if.s in,
    input logic en,
    input logic [CHANNEL_NUMBER_WIDTH-1:0] ctrl,
    axis_if.m out [CHANNEL_NUMBER]
);
    // T channel 
    logic TVALID [CHANNEL_NUMBER];
    logic TREADY [CHANNEL_NUMBER];
    logic [AXIS_DATA_WIDTH-1:0] TDATA [CHANNEL_NUMBER];
    
    `ifdef TSTRB_PRESENT
    logic [(AXIS_DATA_WIDTH/8)-1:0] TSTRB [CHANNEL_NUMBER];
    `endif
    `ifdef TKEEP_PRESENT
    logic [(AXIS_DATA_WIDTH/8)-1:0] TKEEP [CHANNEL_NUMBER];
    `endif
    `ifdef TLAST_PRESENT
    logic TLAST [CHANNEL_NUMBER];
    `endif
    `ifdef TID_PRESENT
    logic [ID_WIDTH-1:0] TID [CHANNEL_NUMBER];
    `endif
    `ifdef TDEST_PRESENT
    logic [DEST_WIDTH-1:0] TDEST [CHANNEL_NUMBER];
    `endif
    `ifdef TUSER_PRESENT
    logic [USER_WIDTH-1:0] TUSER [CHANNEL_NUMBER];
    `endif

    generate
        genvar i;
        for (i = 0; i < CHANNEL_NUMBER; i++) begin : interface_deassembler
            
            assign TREADY[i] = out[i].TREADY;

            // T channel 
            assign out[i].TVALID = TVALID[i];
            assign out[i].TDATA  = TDATA[i];
            
            `ifdef TSTRB_PRESENT
            assign out[i].TSTRB = TSTRB[i];
            `endif
            `ifdef TKEEP_PRESENT
            assign out[i].TKEEP = TKEEP[i];
            `endif
            `ifdef TLAST_PRESENT
            assign out[i].TLAST = TLAST[i];
            `endif
            `ifdef TID_PRESENT
            assign out[i].TID   = TID[i];
            `endif
            `ifdef TDEST_PRESENT
            assign out[i].TDEST = TDEST[i];
            `endif
            `ifdef TUSER_PRESENT
            assign out[i].TUSER = TUSER[i];
            `endif
            
        end
    endgenerate

    always_comb begin

        for(int i = 0; i < CHANNEL_NUMBER; i++) begin
            TVALID[i] = '0;
            TDATA[i]  = '0;
        
            `ifdef TSTRB_PRESENT
            TSTRB[i] = '0;
            `endif
            `ifdef TKEEP_PRESENT
            TKEEP[i] = '0;
            `endif
            `ifdef TLAST_PRESENT
            TLAST[i] = '0;
            `endif
            `ifdef TID_PRESENT
            TID[i] =   '0;
            `endif
            `ifdef TDEST_PRESENT
            TDEST[i] = '0;
            `endif
            `ifdef TUSER_PRESENT
            TUSER[i] = '0;
            `endif

        end

        in.TREADY = TREADY[ctrl];
        
        // T channel 
        TVALID[ctrl] = in.TVALID;
        TDATA[ctrl]  = in.TDATA;
        
        `ifdef TSTRB_PRESENT
        TSTRB[ctrl] = in.TSTRB;
        `endif
        `ifdef TKEEP_PRESENT
        TKEEP[ctrl] = in.TKEEP;
        `endif
        `ifdef TLAST_PRESENT
        TLAST[ctrl] = in.TLAST;
        `endif
        `ifdef TID_PRESENT
        TID[ctrl] =   in.TID;
        `endif
        `ifdef TDEST_PRESENT
        TDEST[ctrl] = in.TDEST;
        `endif
        `ifdef TUSER_PRESENT
        TUSER[ctrl] = in.TUSER;
        `endif

    end

endmodule