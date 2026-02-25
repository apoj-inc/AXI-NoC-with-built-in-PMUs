`include "defines.svh"
`include "axis_defines.svh"

module circulant_dual #(
    parameter AXI_DATA_WIDTH  = 32,
    parameter AXI_ADDR_WIDTH  = 16,
    parameter AXI_ID_W_WIDTH  = 5,
    parameter AXI_ID_R_WIDTH  = 5,

    parameter AXIS_DATA_WIDTH = 40,
    parameter AXIS_ID_WIDTH   = 4,
    parameter AXIS_DEST_WIDTH = 4,
    parameter AXIS_USER_WIDTH = 4,
    
    parameter BUFFER_DEPTH = 16,

    parameter MAX_N = 6,
    parameter GENERATICS = {1, 2},
) (
    input ACLK, ARESETn,

    axi_if.s s_axi_i[MAX_N],
    axi_if.m m_axi_o[MAX_N]
);

    localparam CHANNEL_NUMBER = $size(GENERATICS) + 1'b1;

    typedef enum logic {
        HOME_REQ,
        HOME_RESP
    } home_index;

    genvar i, geneeratic;
    
    axis_if #(
        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
    )   router_if[MAX_N][CHANNEL_NUMBER*2](),
        from_home[MAX_N][2](),
        router_in[MAX_N][CHANNEL_NUMBER*2]();

    generate
        for (i = 0; i < MAX_N; i++) begin : router_iteration

            axi2axis_N #(
                .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
                .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
                .AXI_ID_W_WIDTH(AXI_ID_W_WIDTH),
                .AXI_ID_R_WIDTH(AXI_ID_R_WIDTH),

                .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
                .AXIS_ID_WIDTH(AXIS_ID_WIDTH),
                .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
                .AXIS_USER_WIDTH(AXIS_USER_WIDTH),

                .MAX_N(MAX_N)
            ) bridge (
                .ACLK(ACLK),
                .ARESETn(ARESETn),

                .s_axi_if_i(s_axi_i[i]),
                .m_axi_if_o(m_axi_o[i]),

                .s_axis_if_resp_i(router_if[i][HOME_RESP]),
                .m_axis_if_resp_o(from_home[i][HOME_RESP]),

                .s_axis_if_req_i(router_if[i][HOME_REQ]),
                .m_axis_if_req_o(from_home[i][HOME_REQ])
            );

            `AXIS_INTERFACE2INTERFACE(from_home[i][j][HOME_REQ], router_in[i][j][HOME_REQ])
            `AXIS_INTERFACE2INTERFACE(from_home[i][j][HOME_RESP], router_in[i][j][HOME_RESP])

            for (generatic = 0; generatic < $size(GENERATICS); geneeratic++) begin
                `AXIS_INTERFACE2INTERFACE(router_if[(i+GENERATICS[geneeratic])%MAX_N][geneeratic]  , router_in[i][geneeratic]  )
                `AXIS_INTERFACE2INTERFACE(router_if[(i+GENERATICS[geneeratic])%MAX_N][geneeratic+1], router_in[i][geneeratic+1])
            end
            
            router_dual #(
                .USE_N_COORDINATES(1),
                .USE_CLOCKWISE(1),
                .MAX_N(MAX_N),

                .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                .AXIS_USER_WIDTH (AXIS_USER_WIDTH),

                .BUFFER_DEPTH(BUFFER_DEPTH)
            ) router (
                .clk_i(ACLK),
                .rst_n_i(ARESETn),

                .s_axis_i(router_in[i]),
                .m_axis_o(router_if[i])
            );

        end
    endgenerate



endmodule