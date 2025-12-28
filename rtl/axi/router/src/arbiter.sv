`include "axi2axis_typedef.svh"

module arbiter #(
    parameter DATA_WIDTH = 32
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
    ,
    parameter CHANNEL_NUMBER = 5,
    parameter CHANNEL_NUMBER_WIDTH
    = $clog2(CHANNEL_NUMBER),
    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y = 4,
    parameter MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y),
    parameter MAXIMUM_PACKAGES_NUMBER = 5,
    parameter MAXIMUM_PACKAGES_NUMBER_WIDTH
    = $clog2(MAXIMUM_PACKAGES_NUMBER - 1)
) (
    input clk, rst_n,

    axis_if.s in [CHANNEL_NUMBER],
    axis_if.m out,

    output logic [CHANNEL_NUMBER_WIDTH-1:0] current_grant,

    output logic [MAX_ROUTERS_X_WIDTH-1:0] target_x,
    output logic [MAX_ROUTERS_Y_WIDTH-1:0] target_y
);
    logic [MAX_ROUTERS_X_WIDTH-1:0] target_x_reg [CHANNEL_NUMBER];
    logic [MAX_ROUTERS_Y_WIDTH-1:0] target_y_reg [CHANNEL_NUMBER];
   
    logic [CHANNEL_NUMBER_WIDTH-1:0] next_grant;
    logic [CHANNEL_NUMBER_WIDTH-1:0] increment;

    logic [CHANNEL_NUMBER-1:0] valid_i;
    logic [CHANNEL_NUMBER*2 - 1:0] shifted_valid_i;
    // logic [MAXIMUM_PACKAGES_NUMBER_WIDTH-1:0] packages_left;
    logic [7:0] packages_left [CHANNEL_NUMBER];
    
    logic [DATA_WIDTH-1:0] TDATA [CHANNEL_NUMBER];

    assign target_x = (out.TVALID && (out.TID == ROUTING_HEADER)) ?
                        out.TDATA[
                            MAX_ROUTERS_X_WIDTH+MAX_ROUTERS_Y_WIDTH-1:
                            MAX_ROUTERS_X_WIDTH
                        ] : target_x_reg[current_grant];
    assign target_y = (out.TVALID && (out.TID == ROUTING_HEADER)) ?
                        out.TDATA[
                            MAX_ROUTERS_X_WIDTH-1:0
                        ] : target_y_reg[current_grant];
    
    generate
	    genvar i;
        for (i = 0; i < CHANNEL_NUMBER; i++) begin : valid_gen
            assign valid_i[i] = in[i].TVALID;
            assign TDATA[i] = in[i].TDATA;
        end
    endgenerate

    assign shifted_valid_i = {valid_i, valid_i} >> current_grant;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_grant <= '0;
            for (int i = 0; i < CHANNEL_NUMBER; i++) begin
                packages_left[i] <= '0;
                target_x_reg[i]  <= '0;
                target_y_reg[i]  <= '0;
            end
        end
        else begin
            if (out.TVALID && (out.TID == ROUTING_HEADER)) begin
                packages_left[current_grant] <= out.TDATA[
                    (MAX_ROUTERS_X_WIDTH+MAX_ROUTERS_Y_WIDTH) * 2
                    +8-1:
                    (MAX_ROUTERS_X_WIDTH+MAX_ROUTERS_Y_WIDTH) * 2
                ];
                target_y_reg[current_grant] <= out.TDATA[
                    MAX_ROUTERS_X_WIDTH-1:0
                ];
                target_x_reg[current_grant] <= out.TDATA[
                    MAX_ROUTERS_X_WIDTH+MAX_ROUTERS_Y_WIDTH-1:
                    MAX_ROUTERS_X_WIDTH
                ];
            end
            else begin
                packages_left[current_grant] <= packages_left[current_grant] - (out.TREADY & out.TVALID);
            end
            if (!out.TREADY || !out.TVALID || (packages_left[current_grant] == 1 && out.TVALID && out.TREADY)) begin
                current_grant <= next_grant;
            end
        end
    end

    always_comb begin
        next_grant = current_grant;
        increment = 0;
        for (int i = CHANNEL_NUMBER-1; i > 0; i--) begin
            if (shifted_valid_i[i]) begin
                increment = i;
            end
        end

        next_grant = (next_grant + increment) >= CHANNEL_NUMBER ?
        (next_grant + increment - CHANNEL_NUMBER):
        (next_grant + increment);
    end

    axis_if_mux #(
        .CHANNEL_NUMBER(CHANNEL_NUMBER),
        .DATA_WIDTH(DATA_WIDTH)
        `ifdef TID_PRESENT
        ,
        .ID_WIDTH(ID_WIDTH)
        `endif
        `ifdef TDEST_PRESENT
        ,
        .DEST_WIDTH(DEST_WIDTH)
        `endif
        `ifdef TUSER_PRESENT
        ,
        .USER_WIDTH(USER_WIDTH)
        `endif
    ) mux (
        in,
        1'b1,
        current_grant,
        out
    );

    
endmodule
