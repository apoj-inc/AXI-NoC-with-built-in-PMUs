module XY_mesh #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter MAX_ID_WIDTH = 4,

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

    axis_miso_t from_home_miso[MAX_ROUTERS_Y+2][MAX_ROUTERS_X+2][5];
    axis_mosi_t from_home_mosi[MAX_ROUTERS_Y+2][MAX_ROUTERS_X+2][5];

    generate
        genvar i;
        genvar j;

        for (i = 0; i < MAX_ROUTERS_Y; i++) begin : zeroing_Y
            assign router_if[i][0][WEST].TVALID = '0;
            assign router_if[i][MAX_ROUTERS_X+1][EAST].TVALID = '0;

            assign router_if[i][0][WEST].TREADY = '1;
            assign router_if[i][MAX_ROUTERS_X+1][EAST].TREADY = '1;
        end

        for (i = 0; i < MAX_ROUTERS_X; i++) begin : zeroing_X
            assign router_if[0][i][NORTH].TVALID = '0;
            assign router_if[MAX_ROUTERS_Y+1][i][SOUTH].TVALID = '0;

            assign router_if[0][i][NORTH].TREADY = '1;
            assign router_if[MAX_ROUTERS_Y+1][i][SOUTH].TREADY = '1;
        end
    endgenerate

    generate
        for (i = 0; i < MAX_ROUTERS_Y; i++) begin : Y
            for (j = 0; j < MAX_ROUTERS_X; j++) begin : X
                
                axi2axis_XY #(
                    .ADDR_WIDTH(ADDR_WIDTH),
                    .DATA_WIDTH(DATA_WIDTH),
                    .ID_W_WIDTH(ID_W_WIDTH),
                    .ID_R_WIDTH(ID_R_WIDTH),
                    .MAX_ID_WIDTH(MAX_ID_WIDTH),

                    .ROUTER_X(j),
                    .MAX_ROUTERS_X(MAX_ROUTERS_X),
                    .ROUTER_Y(i),
                    .MAX_ROUTERS_Y(MAX_ROUTERS_Y),

                    .Ax_FIFO_LEN(Ax_FIFO_LEN),
                    .W_FIFO_LEN(W_FIFO_LEN)
                ) bridge (
                    .ACLK(ACLK),
                    .ARESETn(ARESETn),

                    .s_axi_i(s_axi_i[i * MAX_ROUTERS_X + j]),
                    .s_axi_o(s_axi_o[i * MAX_ROUTERS_X + j]),
                    .s_axis_i(router_if_mosi[i+1][j+1][HOME]),
                    .s_axis_o(router_if_miso[i+1][j+1][HOME]),

                    .m_axi_i(m_axi_o[i * MAX_ROUTERS_X + j]),
                    .m_axi_o(m_axi_o[i * MAX_ROUTERS_X + j]),
                    .m_axis_i(from_home_miso[i+1][j+1]),
                    .m_axis_o(from_home_mosi[i+1][j+1])
                );

                router #(
                    .DATA_WIDTH(40),
                    .ROUTER_X(j),
                    .MAX_ROUTERS_X(MAX_ROUTERS_X),
                    .ROUTER_Y(i),
                    .MAX_ROUTERS_Y(MAX_ROUTERS_Y)
                ) router (
                    .clk(ACLK),
                    .rst_n(ARESETn),

                    .in_mosi_i('{from_home_mosi[i+1][j+1], router_if_mosi[i][j+1][SOUTH], router_if_mosi[i+1][j+2][WEST], router_if_mosi[i+2][j+1][NORTH], router_if_mosi[i+1][j][EAST]}),
                    .in_miso_o('{from_home_miso[i+1][j+1], router_if_miso[i][j+1][SOUTH], router_if_miso[i+1][j+2][WEST], router_if_miso[i+2][j+1][NORTH], router_if_miso[i+1][j][EAST]}),

                    .out_miso_i(router_if_miso[i+1][j+1]),
                    .out_mosi_o(router_if_mosi[i+1][j+1])
                );

            end
        end
    endgenerate



endmodule