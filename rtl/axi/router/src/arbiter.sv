`include "defines.svh"

module arbiter #(
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
    `endif,
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
    input clk_i, rst_n_i,

    input  axis_mosi_t in_mosi_i [CHANNEL_NUMBER],
    output axis_miso_t in_miso_o [CHANNEL_NUMBER],
    output axis_mosi_t out_mosi_o,
    input  axis_miso_t out_miso_i,

    output logic [CHANNEL_NUMBER_WIDTH-1:0] current_grant_o,

    output logic [MAX_ROUTERS_X_WIDTH-1:0] target_x_o,
    output logic [MAX_ROUTERS_Y_WIDTH-1:0] target_y_o
);

    `include "axis_type.svh"
    
    logic [MAX_ROUTERS_X_WIDTH-1:0] target_x_reg [CHANNEL_NUMBER];
    logic [MAX_ROUTERS_Y_WIDTH-1:0] target_y_reg [CHANNEL_NUMBER];
   
    logic [CHANNEL_NUMBER_WIDTH-1:0] next_grant;
    logic [CHANNEL_NUMBER_WIDTH-1:0] increment;

    logic [CHANNEL_NUMBER-1:0] valid_i;
    logic [CHANNEL_NUMBER*2 - 1:0] shifted_valid_i;
    // logic [MAXIMUM_PACKAGES_NUMBER_WIDTH-1:0] packages_left;
    logic [7:0] packages_left [CHANNEL_NUMBER];
    
    axis_data_t data [CHANNEL_NUMBER];

    assign target_x_o = (out_mosi_o.TVALID && (out_mosi_o.data.TID == ROUTING_HEADER)) ?
                        out_mosi_o.data.TDATA[
                            MAX_ROUTERS_X_WIDTH+MAX_ROUTERS_Y_WIDTH-1:
                            MAX_ROUTERS_X_WIDTH
                        ] : target_x_reg[current_grant_o];
    assign target_y_o = (out_mosi_o.TVALID && (out_mosi_o.data.TID == ROUTING_HEADER)) ?
                        out_mosi_o.data.TDATA[
                            MAX_ROUTERS_X_WIDTH-1:0
                        ] : target_y_reg[current_grant_o];
    
    generate
	    genvar i;
        for (i = 0; i < CHANNEL_NUMBER; i++) begin : valid_gen
            assign valid_i[i] = in_mosi_i[i].TVALID;
        end
    endgenerate

    assign shifted_valid_i = {valid_i, valid_i} >> current_grant_o;

    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            current_grant_o <= '0;
            for (int i = 0; i < CHANNEL_NUMBER; i++) begin
                packages_left[i] <= '0;
                target_x_reg[i]  <= '0;
                target_y_reg[i]  <= '0;
            end
        end
        else begin
            if (out_mosi_o.TVALID && (out_mosi_o.data.TID == ROUTING_HEADER)) begin
                packages_left[current_grant_o] <= out_mosi_o.data.TDATA[
                    (MAX_ROUTERS_X_WIDTH+MAX_ROUTERS_Y_WIDTH) * 2
                    +8-1:
                    (MAX_ROUTERS_X_WIDTH+MAX_ROUTERS_Y_WIDTH) * 2
                ];
                target_y_reg[current_grant_o] <= out_mosi_o.data.TDATA[
                    MAX_ROUTERS_X_WIDTH-1:0
                ];
                target_x_reg[current_grant_o] <= out_mosi_o.data.TDATA[
                    MAX_ROUTERS_X_WIDTH+MAX_ROUTERS_Y_WIDTH-1:
                    MAX_ROUTERS_X_WIDTH
                ];
            end
            else begin
                packages_left[current_grant_o] <= packages_left[current_grant_o] - (in_miso_o[current_grant_o].TREADY & out_mosi_o.TVALID);
            end
            if (!in_miso_o[current_grant_o].TREADY || !out_mosi_o.TVALID || (packages_left[current_grant_o] == 1 && out_mosi_o.TVALID && in_miso_o[current_grant_o].TREADY)) begin
                current_grant_o <= next_grant;
            end
        end
    end

    always_comb begin
        next_grant = current_grant_o;
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

    always_comb begin
        for (int i = 0; i < CHANNEL_NUMBER; i++) begin
            in_miso_o[i] = '0;
        end
        out_mosi_o = in_mosi_i[current_grant_o];
        in_miso_o[current_grant_o] = out_miso_i;
    end
    
endmodule
