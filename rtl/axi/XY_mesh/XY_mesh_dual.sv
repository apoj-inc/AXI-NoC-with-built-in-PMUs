`include "defines.svh"

module XY_mesh_dual #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 8,
    parameter ID_W_WIDTH = 5,
    parameter ID_R_WIDTH = 5,
    `ifdef TID_PRESENT
    parameter ID_WIDTH = 4,
    `else
    parameter ID_WIDTH = 0,
    `endif
    `ifdef TDEST_PRESENT
    parameter DEST_WIDTH = 4,
    `else
    parameter DEST_WIDTH = 0,
    `endif
    `ifdef TUSER_PRESENT
    parameter USER_WIDTH = 4,
    `else
    parameter USER_WIDTH = 0,
    `endif

    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y = 4,
    parameter MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y),

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

    localparam ROUTING_HEADER_EFFECTIVE = 8 + (MAX_ROUTERS_X_WIDTH + MAX_ROUTERS_Y_WIDTH) * 2;
    localparam ROUTING_HEADER_WIDTH = (ROUTING_HEADER_EFFECTIVE / 8 + ((ROUTING_HEADER_EFFECTIVE % 8) != 0)) * 8;

    localparam AW_SUBHEADER_EFFECTIVE = ID_W_WIDTH + ADDR_WIDTH + 8 + 3 + 2;
    localparam AW_SUBHEADER_WIDTH = (AW_SUBHEADER_EFFECTIVE / 8 + ((AW_SUBHEADER_EFFECTIVE % 8) != 0)) * 8;

    localparam B_SUBHEADER_EFFECTIVE = ID_W_WIDTH;
    localparam B_SUBHEADER_WIDTH = (B_SUBHEADER_EFFECTIVE / 8 + ((B_SUBHEADER_EFFECTIVE % 8) != 0)) * 8;

    localparam W_DATA_EFFECTIVE = DATA_WIDTH;
    localparam W_DATA_WIDTH = (W_DATA_EFFECTIVE / 8 + ((W_DATA_EFFECTIVE % 8) != 0)) * 8;

    localparam AR_SUBHEADER_EFFECTIVE = ID_R_WIDTH + ADDR_WIDTH + 8 + 3 + 2;
    localparam AR_SUBHEADER_WIDTH = (AR_SUBHEADER_EFFECTIVE / 8 + ((AR_SUBHEADER_EFFECTIVE % 8) != 0)) * 8;

    localparam R_DATA_EFFECTIVE = ID_R_WIDTH + DATA_WIDTH;
    localparam R_DATA_WIDTH = (R_DATA_EFFECTIVE / 8 + ((R_DATA_EFFECTIVE % 8) != 0)) * 8;

    localparam COMP_1 = (ROUTING_HEADER_WIDTH > AW_SUBHEADER_WIDTH) ? ROUTING_HEADER_WIDTH : AW_SUBHEADER_WIDTH;
    localparam COMP_2 = (B_SUBHEADER_WIDTH > W_DATA_WIDTH) ? B_SUBHEADER_WIDTH : W_DATA_WIDTH;
    localparam COMP_3 = (AR_SUBHEADER_WIDTH > R_DATA_WIDTH) ? AR_SUBHEADER_WIDTH : R_DATA_WIDTH;

    localparam COMP_4 = (COMP_1 > COMP_2) ? COMP_1 : COMP_2;
    localparam AXIS_CHANNEL_WIDTH = (COMP_3 > COMP_4) ? COMP_3 : COMP_4;

    typedef enum logic [3:0] {
        HOME_REQ,
        HOME_RESP,
        NORTH_REQ,
        NORTH_RESP,
        EAST_REQ,
        EAST_RESP,
        SOUTH_REQ,
        SOUTH_RESP,
        WEST_REQ,
        WEST_RESP
    } index;
    
    axis_miso_t router_if_miso[MAX_ROUTERS_Y+2][MAX_ROUTERS_X+2][10];
    axis_mosi_t router_if_mosi[MAX_ROUTERS_Y+2][MAX_ROUTERS_X+2][10];

    axis_miso_t from_home_miso[MAX_ROUTERS_Y][MAX_ROUTERS_X][2];
    axis_mosi_t from_home_mosi[MAX_ROUTERS_Y][MAX_ROUTERS_X][2];

    axis_miso_t router_i_miso[MAX_ROUTERS_Y][MAX_ROUTERS_X][10];
    axis_mosi_t router_i_mosi[MAX_ROUTERS_Y][MAX_ROUTERS_X][10];

    generate
        genvar i;
        genvar j;

        for (i = 0; i < MAX_ROUTERS_Y; i++) begin : zeroing_Y
            assign router_if_mosi[i][0][WEST_REQ].TVALID = '0;
            assign router_if_mosi[i][0][WEST_RESP].TVALID = '0;
            assign router_if_mosi[i][MAX_ROUTERS_X+1][EAST_REQ].TVALID = '0;
            assign router_if_mosi[i][MAX_ROUTERS_X+1][EAST_RESP].TVALID = '0;

            assign router_if_miso[i][0][WEST_REQ].TREADY = '1;
            assign router_if_miso[i][0][WEST_RESP].TREADY = '1;
            assign router_if_miso[i][MAX_ROUTERS_X+1][EAST_REQ].TREADY = '1;
            assign router_if_miso[i][MAX_ROUTERS_X+1][EAST_RESP].TREADY = '1;
        end

        for (i = 0; i < MAX_ROUTERS_X; i++) begin : zeroing_X
            assign router_if_mosi[0][i][NORTH_REQ].TVALID = '0;
            assign router_if_mosi[0][i][NORTH_RESP].TVALID = '0;
            assign router_if_mosi[MAX_ROUTERS_Y+1][i][SOUTH_REQ].TVALID = '0;
            assign router_if_mosi[MAX_ROUTERS_Y+1][i][SOUTH_RESP].TVALID = '0;

            assign router_if_miso[0][i][NORTH_REQ].TREADY = '1;
            assign router_if_miso[0][i][NORTH_RESP].TREADY = '1;
            assign router_if_miso[MAX_ROUTERS_Y+1][i][SOUTH_REQ].TREADY = '1;
            assign router_if_miso[MAX_ROUTERS_Y+1][i][SOUTH_RESP].TREADY = '1;
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
                    .AXIS_CHANNEL_WIDTH(AXIS_CHANNEL_WIDTH),

                    .ID_WIDTH(ID_WIDTH),
                    .DEST_WIDTH(DEST_WIDTH),
                    .USER_WIDTH(USER_WIDTH),

                    .ROUTER_X(j),
                    .MAX_ROUTERS_X(MAX_ROUTERS_X),
                    .ROUTER_Y(i),
                    .MAX_ROUTERS_Y(MAX_ROUTERS_Y)
                ) bridge (
                    .ACLK(ACLK),
                    .ARESETn(ARESETn),

                    .s_axi_i(s_axi_i[i * MAX_ROUTERS_X + j]),
                    .s_axi_o(s_axi_o[i * MAX_ROUTERS_X + j]),

                    .s_axis_req_i(router_if_mosi[i+1][j+1][HOME_REQ]),
                    .s_axis_req_o(router_if_miso[i+1][j+1][HOME_REQ]),

                    .s_axis_req_i(router_if_mosi[i+1][j+1][HOME_RESP]),
                    .s_axis_req_o(router_if_miso[i+1][j+1][HOME_RESP]),


                    .m_axi_i(m_axi_i[i * MAX_ROUTERS_X + j]),
                    .m_axi_o(m_axi_o[i * MAX_ROUTERS_X + j]),

                    .m_axis_req_i(from_home_miso[i][j][HOME_REQ]),
                    .m_axis_req_o(from_home_mosi[i][j][HOME_REQ]),

                    .m_axis_resp_i(from_home_miso[i][j][HOME_RESP]),
                    .m_axis_resp_o(from_home_mosi[i][j][HOME_RESP])

                );


                assign router_i_mosi[i][j][0].TVALID =                  from_home_mosi[i][j][HOME_REQ].TVALID;
                assign from_home_miso[i][j][HOME_REQ].TREADY = router_i_miso[i][j][0].TREADY;
                assign router_i_mosi[i][j][0].data.TDATA =                   from_home_mosi[i][j][HOME_REQ].data.TDATA;
                assign router_i_mosi[i][j][0].data.TID =                     from_home_mosi[i][j][HOME_REQ].data.TID;
                assign router_i_mosi[i][j][0].data.TSTRB =                   from_home_mosi[i][j][HOME_REQ].data.TSTRB;
                assign router_i_mosi[i][j][0].data.TLAST =                   from_home_mosi[i][j][HOME_REQ].data.TLAST;

                assign router_i_mosi[i][j][1].TVALID =                  from_home_mosi[i][j][HOME_RESP].TVALID;
                assign from_home_miso[i][j][HOME_RESP].TREADY = router_i_miso[i][j][1].TREADY;
                assign router_i_mosi[i][j][1].data.TDATA =                   from_home_mosi[i][j][HOME_RESP].data.TDATA;
                assign router_i_mosi[i][j][1].data.TID =                     from_home_mosi[i][j][HOME_RESP].data.TID;
                assign router_i_mosi[i][j][1].data.TSTRB =                   from_home_mosi[i][j][HOME_RESP].data.TSTRB;
                assign router_i_mosi[i][j][1].data.TLAST =                   from_home_mosi[i][j][HOME_RESP].data.TLAST;

                assign router_i_mosi[i][j][2].TVALID =                  router_if_mosi[i][j+1][SOUTH_REQ].TVALID;
                assign router_if_miso[i][j+1][SOUTH_REQ].TREADY = router_i_miso[i][j][2].TREADY;
                assign router_i_mosi[i][j][2].data.TDATA =                   router_if_mosi[i][j+1][SOUTH_REQ].data.TDATA;
                assign router_i_mosi[i][j][2].data.TID =                     router_if_mosi[i][j+1][SOUTH_REQ].data.TID;
                assign router_i_mosi[i][j][2].data.TSTRB =                   router_if_mosi[i][j+1][SOUTH_REQ].data.TSTRB;
                assign router_i_mosi[i][j][2].data.TLAST =                   router_if_mosi[i][j+1][SOUTH_REQ].data.TLAST;

                assign router_i_mosi[i][j][3].TVALID =                  router_if_mosi[i][j+1][SOUTH_RESP].TVALID;
                assign router_if_miso[i][j+1][SOUTH_RESP].TREADY = router_i_miso[i][j][3].TREADY;
                assign router_i_mosi[i][j][3].data.TDATA =                   router_if_mosi[i][j+1][SOUTH_RESP].data.TDATA;
                assign router_i_mosi[i][j][3].data.TID =                     router_if_mosi[i][j+1][SOUTH_RESP].data.TID;
                assign router_i_mosi[i][j][3].data.TSTRB =                   router_if_mosi[i][j+1][SOUTH_RESP].data.TSTRB;
                assign router_i_mosi[i][j][3].data.TLAST =                   router_if_mosi[i][j+1][SOUTH_RESP].data.TLAST;

                assign router_i_mosi[i][j][4].TVALID =                  router_if_mosi[i+1][j+2][WEST_REQ].TVALID;
                assign router_if_miso[i+1][j+2][WEST_REQ].TREADY = router_i_miso[i][j][4].TREADY;
                assign router_i_mosi[i][j][4].data.TDATA =                   router_if_mosi[i+1][j+2][WEST_REQ].data.TDATA;
                assign router_i_mosi[i][j][4].data.TID =                     router_if_mosi[i+1][j+2][WEST_REQ].data.TID;
                assign router_i_mosi[i][j][4].data.TSTRB =                   router_if_mosi[i+1][j+2][WEST_REQ].data.TSTRB;
                assign router_i_mosi[i][j][4].data.TLAST =                   router_if_mosi[i+1][j+2][WEST_REQ].data.TLAST;

                assign router_i_mosi[i][j][5].TVALID =                  router_if_mosi[i+1][j+2][WEST_RESP].TVALID;
                assign router_if_miso[i+1][j+2][WEST_RESP].TREADY = router_i_miso[i][j][5].TREADY;
                assign router_i_mosi[i][j][5].data.TDATA =                   router_if_mosi[i+1][j+2][WEST_RESP].data.TDATA;
                assign router_i_mosi[i][j][5].data.TID =                     router_if_mosi[i+1][j+2][WEST_RESP].data.TID;
                assign router_i_mosi[i][j][5].data.TSTRB =                   router_if_mosi[i+1][j+2][WEST_RESP].data.TSTRB;
                assign router_i_mosi[i][j][5].data.TLAST =                   router_if_mosi[i+1][j+2][WEST_RESP].data.TLAST;

                assign router_i_mosi[i][j][6].TVALID =                  router_if_mosi[i+2][j+1][NORTH_REQ].TVALID;
                assign router_if_miso[i+2][j+1][NORTH_REQ].TREADY = router_i_miso[i][j][6].TREADY;
                assign router_i_mosi[i][j][6].data.TDATA =                   router_if_mosi[i+2][j+1][NORTH_REQ].data.TDATA;
                assign router_i_mosi[i][j][6].data.TID =                     router_if_mosi[i+2][j+1][NORTH_REQ].data.TID;
                assign router_i_mosi[i][j][6].data.TSTRB =                   router_if_mosi[i+2][j+1][NORTH_REQ].data.TSTRB;
                assign router_i_mosi[i][j][6].data.TLAST =                   router_if_mosi[i+2][j+1][NORTH_REQ].data.TLAST;

                assign router_i_mosi[i][j][7].TVALID =                  router_if_mosi[i+2][j+1][NORTH_RESP].TVALID;
                assign router_if_miso[i+2][j+1][NORTH_RESP].TREADY = router_i_miso[i][j][7].TREADY;
                assign router_i_mosi[i][j][7].data.TDATA =                   router_if_mosi[i+2][j+1][NORTH_RESP].data.TDATA;
                assign router_i_mosi[i][j][7].data.TID =                     router_if_mosi[i+2][j+1][NORTH_RESP].data.TID;
                assign router_i_mosi[i][j][7].data.TSTRB =                   router_if_mosi[i+2][j+1][NORTH_RESP].data.TSTRB;
                assign router_i_mosi[i][j][7].data.TLAST =                   router_if_mosi[i+2][j+1][NORTH_RESP].data.TLAST;

                assign router_i_mosi[i][j][8].TVALID =                  router_if_mosi[i+1][j][EAST_REQ].TVALID;
                assign router_if_miso[i+1][j][EAST_REQ].TREADY = router_i_miso[i][j][8].TREADY;
                assign router_i_mosi[i][j][8].data.TDATA =                   router_if_mosi[i+1][j][EAST_REQ].data.TDATA;
                assign router_i_mosi[i][j][8].data.TID =                     router_if_mosi[i+1][j][EAST_REQ].data.TID;
                assign router_i_mosi[i][j][8].data.TSTRB =                   router_if_mosi[i+1][j][EAST_REQ].data.TSTRB;
                assign router_i_mosi[i][j][8].data.TLAST =                   router_if_mosi[i+1][j][EAST_REQ].data.TLAST;

                assign router_i_mosi[i][j][9].TVALID =                  router_if_mosi[i+1][j][EAST_RESP].TVALID;
                assign router_if_miso[i+1][j][EAST_RESP].TREADY = router_i_miso[i][j][9].TREADY;
                assign router_i_mosi[i][j][9].data.TDATA =                   router_if_mosi[i+1][j][EAST_RESP].data.TDATA;
                assign router_i_mosi[i][j][9].data.TID =                     router_if_mosi[i+1][j][EAST_RESP].data.TID;
                assign router_i_mosi[i][j][9].data.TSTRB =                   router_if_mosi[i+1][j][EAST_RESP].data.TSTRB;
                assign router_i_mosi[i][j][9].data.TLAST =                   router_if_mosi[i+1][j][EAST_RESP].data.TLAST;
                
                router_dual #(
                    .DATA_WIDTH(AXIS_CHANNEL_WIDTH),
                    .ROUTER_X(j),
                    .MAX_ROUTERS_X(MAX_ROUTERS_X),
                    .ROUTER_Y(i),
                    .MAX_ROUTERS_Y(MAX_ROUTERS_Y),

                    .ID_WIDTH(3),
                    .DEST_WIDTH(DEST_WIDTH),
                    .USER_WIDTH(USER_WIDTH)

                ) router (
                    .clk(ACLK),
                    .rst_n(ARESETn),

                    .in_mosi_i(router_i_mosi[i][j]),
                    .in_miso_o(router_i_miso[i][j]),

                    .out_miso_i(router_if_miso[i+1][j+1]),
                    .out_mosi_o(router_if_mosi[i+1][j+1])

                );

            end
        end
    endgenerate



endmodule