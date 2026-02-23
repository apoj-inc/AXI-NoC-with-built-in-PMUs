`include "defines.svh"
`include "axi2axis_typedef.svh"

module arbiter #(
    parameter AXIS_DATA_WIDTH = 40,
    parameter AXIS_ID_WIDTH = 4,
    parameter AXIS_DEST_WIDTH = 4,
    parameter AXIS_USER_WIDTH = 4,

    parameter CHANNEL_NUMBER = 5,
    parameter CHANNEL_NUMBER_WIDTH
    = $clog2(CHANNEL_NUMBER),
    parameter MAXIMUM_PACKAGES_NUMBER = 5,
    parameter MAXIMUM_PACKAGES_NUMBER_WIDTH
    = $clog2(MAXIMUM_PACKAGES_NUMBER - 1),
    
    parameter TARGET_LEN          = 0
) (
    input clk_i, rst_n_i,

    axis_if.s s_axis_i [CHANNEL_NUMBER],
    axis_if.m m_axis_o,

    output logic [CHANNEL_NUMBER_WIDTH-1:0] current_grant_o,

    output logic [TARGET_LEN-1:0] target_o
);

    `GENERATE_AXIS_TYPEDEFS
    axis_mosi_t in_mosi_i[CHANNEL_NUMBER], out_mosi_o;
    axis_miso_t in_miso_o[CHANNEL_NUMBER], out_miso_i;

    generate
        genvar j;
        for (j = 0; j < CHANNEL_NUMBER; j++) begin : typedef_to_interface
            `AXIS_INTERFACE_SLAVE2TYPEDEF(s_axis_i[j], in_mosi_i[j], in_miso_o[j])
        end
    endgenerate
    `AXIS_INTERFACE_MASTER2TYPEDEF(m_axis_o, out_mosi_o, out_miso_i)


    logic [TARGET_LEN-1:0] target_reg [CHANNEL_NUMBER];
   
    logic [CHANNEL_NUMBER_WIDTH-1:0] next_grant;
    logic [CHANNEL_NUMBER_WIDTH-1:0] increment;

    logic [CHANNEL_NUMBER-1:0] valid_i;
    logic [CHANNEL_NUMBER*2 - 1:0] shifted_valid_i;
    // logic [MAXIMUM_PACKAGES_NUMBER_WIDTH-1:0] packages_left;
    logic [7:0] packages_left [CHANNEL_NUMBER];
    
    axis_data_t data [CHANNEL_NUMBER];

    assign target_o = (out_mosi_o.TVALID && (out_mosi_o.data.TID == ROUTING_HEADER)) ?
                        out_mosi_o.data.TDATA[TARGET_LEN-1:0] :
                        target_reg[current_grant_o];
    
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
                target_reg[i]  <= '0;
            end
        end
        else begin
            if (out_mosi_o.TVALID && (out_mosi_o.data.TID == ROUTING_HEADER)) begin
                packages_left[current_grant_o] <= out_mosi_o.data.TDATA[
                    TARGET_LEN * 2 +: 8
                ];
                target_reg[current_grant_o] <= out_mosi_o.data.TDATA[
                    TARGET_LEN-1:0
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
