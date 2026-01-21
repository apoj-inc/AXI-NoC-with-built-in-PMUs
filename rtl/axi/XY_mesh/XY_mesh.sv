`include "defines.svh"

module XY_mesh #(
    parameter AXI_DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16,
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter MAX_ID_WIDTH = 4,
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
    `endif,

    parameter MAX_ROUTERS_X = 3,
    parameter MAX_ROUTERS_Y = 3,

    parameter Ax_FIFO_LEN = 4,
    parameter W_FIFO_LEN = 4
) (
    input ACLK, ARESETn,

    input  axi_mosi_t s_axi_i[MAX_ROUTERS_X*MAX_ROUTERS_Y],
    output axi_miso_t s_axi_o[MAX_ROUTERS_X*MAX_ROUTERS_Y],

    input  axi_miso_t m_axi_i[MAX_ROUTERS_X*MAX_ROUTERS_Y],
    output axi_mosi_t m_axi_o[MAX_ROUTERS_X*MAX_ROUTERS_Y]
);

    `include "axi_type.svh"
    `include "axis_type.svh"

    typedef enum logic [2:0] {
        HOME,
        NORTH,
        EAST,
        SOUTH,
        WEST
    } index;
    
    axis_miso_t router_if_miso[MAX_ROUTERS_Y+2][MAX_ROUTERS_X+2][5];
    axis_mosi_t router_if_mosi[MAX_ROUTERS_Y+2][MAX_ROUTERS_X+2][5];

    axis_miso_t from_home_miso[MAX_ROUTERS_Y+2][MAX_ROUTERS_X+2];
    axis_mosi_t from_home_mosi[MAX_ROUTERS_Y+2][MAX_ROUTERS_X+2];

    generate
        genvar i;
        genvar j;

        for (i = 0; i < MAX_ROUTERS_Y; i++) begin : zeroing_Y
            assign router_if_mosi[i][0][WEST].TVALID = '0;
            assign router_if_mosi[i][MAX_ROUTERS_X+1][EAST].TVALID = '0;

            assign router_if_miso[i][0][WEST].TREADY = '1;
            assign router_if_miso[i][MAX_ROUTERS_X+1][EAST].TREADY = '1;
        end

        for (i = 0; i < MAX_ROUTERS_X; i++) begin : zeroing_X
            assign router_if_mosi[0][i][NORTH].TVALID = '0;
            assign router_if_mosi[MAX_ROUTERS_Y+1][i][SOUTH].TVALID = '0;

            assign router_if_miso[0][i][NORTH].TREADY = '1;
            assign router_if_miso[MAX_ROUTERS_Y+1][i][SOUTH].TREADY = '1;
        end
    endgenerate

    generate
        for (i = 0; i < MAX_ROUTERS_Y; i++) begin : Y
            for (j = 0; j < MAX_ROUTERS_X; j++) begin : X
                
                axi2axis_XY #(
                    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
                    .ADDR_WIDTH(ADDR_WIDTH),
                    .ID_W_WIDTH(ID_W_WIDTH),
                    .ID_R_WIDTH(ID_R_WIDTH),

                    .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH)
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
                    `endif,

                    .ROUTER_X(j),
                    .MAX_ROUTERS_X(MAX_ROUTERS_X),
                    .ROUTER_Y(i),
                    .MAX_ROUTERS_Y(MAX_ROUTERS_Y)
                ) bridge (
                    .ACLK(ACLK),
                    .ARESETn(ARESETn),

                    .s_axi_i(s_axi_i[i * MAX_ROUTERS_X + j]),
                    .s_axi_o(s_axi_o[i * MAX_ROUTERS_X + j]),

                    .s_axis_req_i(router_if_mosi[i+1][j+1][HOME]),
                    .s_axis_req_o(router_if_miso[i+1][j+1][HOME]),


                    .m_axi_i(m_axi_i[i * MAX_ROUTERS_X + j]),
                    .m_axi_o(m_axi_o[i * MAX_ROUTERS_X + j]),

                    .m_axis_req_i(from_home_miso[i+1][j+1]),
                    .m_axis_req_o(from_home_mosi[i+1][j+1])
                );

                router #(
                    .DATA_WIDTH(40),
                    .ROUTER_X(j),
                    .MAX_ROUTERS_X(MAX_ROUTERS_X),
                    .ROUTER_Y(i),
                    .MAX_ROUTERS_Y(MAX_ROUTERS_Y),

                    .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH)
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
                ) router (
                    .clk_i(ACLK),
                    .rst_n_i(ARESETn),

                    .in_mosi_i('{from_home_mosi[i+1][j+1], router_if_mosi[i][j+1][SOUTH], router_if_mosi[i+1][j+2][WEST], router_if_mosi[i+2][j+1][NORTH], router_if_mosi[i+1][j][EAST]}),
                    .in_miso_o('{from_home_miso[i+1][j+1], router_if_miso[i][j+1][SOUTH], router_if_miso[i+1][j+2][WEST], router_if_miso[i+2][j+1][NORTH], router_if_miso[i+1][j][EAST]}),

                    .out_miso_i(router_if_miso[i+1][j+1]),
                    .out_mosi_o(router_if_mosi[i+1][j+1])
                );

            end
        end
    endgenerate



endmodule