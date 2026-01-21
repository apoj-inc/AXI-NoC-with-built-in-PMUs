`include "defines.svh"

module axis_if_mux #(
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
    axis_if.s in [CHANNEL_NUMBER],
    input logic en,
    input logic [CHANNEL_NUMBER_WIDTH-1:0] ctrl,
    axis_if.m out
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
            
            assign in[i].TREADY = TREADY[i];

            // T channel 
            assign TVALID[i] = in[i].TVALID;
            assign TDATA [i] = in[i].TDATA;
            
            `ifdef TSTRB_PRESENT
            assign TSTRB[i] = in[i].TSTRB;
            `endif
            `ifdef TKEEP_PRESENT
            assign TKEEP[i] = in[i].TKEEP;
            `endif
            `ifdef TLAST_PRESENT
            assign TLAST[i] = in[i].TLAST;
            `endif
            `ifdef TID_PRESENT
            assign TID[i]   = in[i].TID;
            `endif
            `ifdef TDEST_PRESENT
            assign TDEST[i] = in[i].TDEST;
            `endif
            `ifdef TUSER_PRESENT
            assign TUSER[i] = in[i].TUSER;
            `endif
            
        end
    endgenerate

    always_comb begin

        // T channel 
        out.TVALID = '0;
        out.TDATA  = '0;
        
        `ifdef TSTRB_PRESENT
        out.TSTRB = '0;
        `endif
        `ifdef TKEEP_PRESENT
        out.TKEEP = '0;
        `endif
        `ifdef TLAST_PRESENT
        out.TLAST = '0;
        `endif
        `ifdef TID_PRESENT
        out.TID =   '0;
        `endif
        `ifdef TDEST_PRESENT
        out.TDEST = '0;
        `endif
        `ifdef TUSER_PRESENT
        out.TUSER = '0;
        `endif

        for(int i = 0; i < CHANNEL_NUMBER; i++)
            TREADY[i] = '0;

        if(en) begin
            
            // T channel 
            out.TVALID = TVALID[ctrl];
            out.TDATA  = TDATA[ctrl];
            
            `ifdef TSTRB_PRESENT
            out.TSTRB = TSTRB[ctrl];
            `endif
            `ifdef TKEEP_PRESENT
            out.TKEEP = TKEEP[ctrl];
            `endif
            `ifdef TLAST_PRESENT
            out.TLAST = TLAST[ctrl];
            `endif
            `ifdef TID_PRESENT
            out.TID =   TID[ctrl];
            `endif
            `ifdef TDEST_PRESENT
            out.TDEST = TDEST[ctrl];
            `endif
            `ifdef TUSER_PRESENT
            out.TUSER = TUSER[ctrl];
            `endif

            TREADY[ctrl] = out.TREADY;
        end

    end

endmodule