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

    parameter ROUTERS_N = 6,
    parameter GENERATICS_COUNT = 2,
    parameter int GENERATICS[GENERATICS_COUNT] = '{1, 2}
) (
    input ACLK, ARESETn,

    axi_if.s s_axi_i[ROUTERS_N],
    axi_if.m m_axi_o[ROUTERS_N]
);

    int test_previous_generatic;
    int test_i;

    initial begin //GENERATICS sanity test
    assert (GENERATICS_COUNT > 0) else $error("No generatics passed!");
    test_previous_generatic = 0;
    for(test_i = 0; test_i < GENERATICS_COUNT; test_i++) begin
        assert (GENERATICS[test_i] > test_previous_generatic) else $error("Generatics order broken!");
        test_previous_generatic = GENERATICS[test_i];
    end

    assert (test_previous_generatic < ROUTERS_N) else $error("Generatics greater than routers!");
    end

    localparam CHANNEL_NUMBER = (GENERATICS_COUNT + 1'b1)*2;

    typedef enum logic {
        HOME_REQ,
        HOME_RESP
    } home_index;

    genvar i, generatic;
    
    axis_if #(
        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
    )   router_if[ROUTERS_N][CHANNEL_NUMBER](),
        from_home[ROUTERS_N][2](),
        router_in[ROUTERS_N][CHANNEL_NUMBER]();

    generate
        for (i = 0; i < ROUTERS_N; i++) begin : router_iteration

            axi2axis_N #(
                .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
                .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
                .AXI_ID_W_WIDTH(AXI_ID_W_WIDTH),
                .AXI_ID_R_WIDTH(AXI_ID_R_WIDTH),

                .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
                .AXIS_ID_WIDTH(AXIS_ID_WIDTH),
                .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
                .AXIS_USER_WIDTH(AXIS_USER_WIDTH),

                .ROUTER_N(i),
                .ROUTERS_N(ROUTERS_N)
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

            `AXIS_INTERFACE2INTERFACE(from_home[i][HOME_REQ], router_in[i][HOME_REQ])
            `AXIS_INTERFACE2INTERFACE(from_home[i][HOME_RESP], router_in[i][HOME_RESP])

            for (generatic = 0; generatic < GENERATICS_COUNT; generatic++) begin
                `AXIS_INTERFACE2INTERFACE(router_if[(i+GENERATICS[generatic])%ROUTERS_N][generatic*2+2]  , router_in[i][generatic*2+2]  )
                `AXIS_INTERFACE2INTERFACE(router_if[(i+GENERATICS[generatic])%ROUTERS_N][generatic*2+1+2], router_in[i][generatic*2+1+2])
            end
            
            router_dual #(
                .CHANNEL_NUMBER(CHANNEL_NUMBER),
                .USE_N_COORDINATES(1),
                .USE_CLOCKWISE(1),
                .ROUTER_N(i),
                .ROUTERS_N(ROUTERS_N),

                .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                .AXIS_USER_WIDTH (AXIS_USER_WIDTH),

                .BUFFER_DEPTH(BUFFER_DEPTH),
                .GENERATICS_COUNT(GENERATICS_COUNT),
                .GENERATICS(GENERATICS)
            ) router (
                .clk_i(ACLK),
                .rst_n_i(ARESETn),

                .s_axis_i(router_in[i]),
                .m_axis_o(router_if[i])
            );

        end
    endgenerate



endmodule