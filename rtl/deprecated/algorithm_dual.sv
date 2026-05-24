`include "defines.svh"
`include "axis_defines.svh"
`include "axi2axis_typedef.svh"

module algorithm_dual #(
    parameter        AXIS_DATA_WIDTH = 40,
    parameter        AXIS_ID_WIDTH = 4,
    parameter        AXIS_DEST_WIDTH = 4,
    parameter        AXIS_USER_WIDTH = 4,

    parameter        CHANNEL_NUMBER = 10,
    parameter        CHANNEL_NUMBER_WIDTH = $clog2(CHANNEL_NUMBER),
    parameter string TOPOLOGY = "Mesh",
    parameter string ALGORITHM = "XY",
    parameter string COORDINATES = "XY",
    
    parameter        TARGET_LEN     = 0,

    // Algorithm and topology specific parameters
    // Mesh and Torus
    parameter        MAX_ROUTERS_X = 4,
    parameter        MAX_ROUTERS_X_WIDTH = $clog2(MAX_ROUTERS_X),
    parameter        MAX_ROUTERS_Y = 4,
    parameter        MAX_ROUTERS_Y_WIDTH = $clog2(MAX_ROUTERS_Y),
    parameter        ROUTER_X = 0,
    parameter        ROUTER_Y = 0,
    
    // Circulant
    parameter        ROUTER_N = 0,
    parameter        ROUTERS_COUNT = 6,
    parameter        GENERATICS_COUNT = 2,
    parameter int    GENERATICS[GENERATICS_COUNT] = '{2, 1}
) (
    input clk_i, rst_n_i,
    
    axis_if.s s_axis_i,
    axis_if.m m_axis_o [CHANNEL_NUMBER],

    input logic [CHANNEL_NUMBER_WIDTH-1:0] current_grant_i,
    input logic [TARGET_LEN-1:0] target_i
);

    `GENERATE_AXIS_TYPEDEFS
    axis_mosi_t in_mosi_i, out_mosi_o[CHANNEL_NUMBER];
    axis_miso_t in_miso_o, out_miso_i[CHANNEL_NUMBER];

    `AXIS_INTERFACE_SLAVE2TYPEDEF(s_axis_i, in_mosi_i, in_miso_o)
    generate
        genvar i;
        for (i = 0; i < CHANNEL_NUMBER; i++) begin : typedef_to_interface
            `AXIS_INTERFACE_MASTER2TYPEDEF(m_axis_o[i], out_mosi_o[i], out_miso_i[i])
        end
    endgenerate

    logic [MAX_ROUTERS_Y_WIDTH-1:0] target_y_i;
    logic [MAX_ROUTERS_X_WIDTH-1:0] target_x_i;

    generate
        if(COORDINATES == "XY") begin : xy_unwrap
            assign target_y_i =
                target_i[MAX_ROUTERS_Y_WIDTH-1:0];
            assign target_x_i =
                target_i[MAX_ROUTERS_Y_WIDTH+MAX_ROUTERS_X_WIDTH-1 -: MAX_ROUTERS_X_WIDTH];
        end
        else if (COORDINATES == "N") begin
        end
        else begin
            initial $error("Wrong coordinate system! (COORDINATES == %s)", COORDINATES);
        end
    endgenerate

    logic [CHANNEL_NUMBER_WIDTH-1-1:0] ctrl_logical;
    logic [CHANNEL_NUMBER_WIDTH-1:0] ctrl;

    assign ctrl = (ctrl_logical << 1) | current_grant_i[0];

    logic [CHANNEL_NUMBER-1:0] busy;
    logic [CHANNEL_NUMBER-1:0] busy_next;

    generate
        if(TOPOLOGY == "Mesh") begin : mesh_topology
            if (ALGORITHM == "XY") begin : xy_alg
                algorithm_selector_mesh_XY #(
                    .MAX_ROUTERS_X(MAX_ROUTERS_X), 
                    .MAX_ROUTERS_Y(MAX_ROUTERS_Y), 
                    .ROUTER_X(ROUTER_X),
                    .ROUTER_Y(ROUTER_Y),
                    .CHANNEL_NUMBER(CHANNEL_NUMBER/2)
                ) algorithm_selector (
                    .target_x_i(target_x_i),
                    .target_y_i(target_y_i),
                    .selector_o(ctrl_logical)
                );
            end
            else begin : mesh_alg_error
                initial $error("Wrong algorithm for the topology %s! (ALGORITHM == %s)", TOPOLOGY, ALGORITHM);
            end
        end
        else if(TOPOLOGY == "Torus") begin : torus_topology
            if (ALGORITHM == "XY") begin : xy_alg
                algorithm_selector_torus_XY #(
                    .MAX_ROUTERS_X(MAX_ROUTERS_X), 
                    .MAX_ROUTERS_Y(MAX_ROUTERS_Y), 
                    .ROUTER_X(ROUTER_X),
                    .ROUTER_Y(ROUTER_Y),
                    .CHANNEL_NUMBER(CHANNEL_NUMBER/2)
                ) algorithm_selector (
                    .target_x_i(target_x_i),
                    .target_y_i(target_y_i),
                    .selector_o(ctrl_logical)
                );
            end
            else if (ALGORITHM == "EWn_SNe") begin : ewn_sne_alg
                algorithm_selector_torus_EWn_SNe #(
                    .MAX_ROUTERS_X(MAX_ROUTERS_X), 
                    .MAX_ROUTERS_Y(MAX_ROUTERS_Y), 
                    .ROUTER_X(ROUTER_X),
                    .ROUTER_Y(ROUTER_Y),
                    .CHANNEL_NUMBER(CHANNEL_NUMBER/2)
                ) algorithm_selector (
                    .target_x_i(target_x_i),
                    .target_y_i(target_y_i),
                    .incoming_channel_i(current_grant_i[CHANNEL_NUMBER_WIDTH-1:1]),
                    .selector_o(ctrl_logical)
                );
            end
            else begin : torus_alg_error
                initial $error("Wrong algorithm for the topology %s! (ALGORITHM == %s)", TOPOLOGY, ALGORITHM);
            end
        end
        else if(TOPOLOGY == "Circulant") begin : circulant_topology
            if (ALGORITHM == "Clockwise") begin : clockwise_alg
                algorithm_selector_clockwise #(
                .ROUTER_N(ROUTER_N),
                .ROUTERS_COUNT(ROUTERS_COUNT),
                .GENERATICS_COUNT(GENERATICS_COUNT),
                .GENERATICS(GENERATICS),
                .CHANNEL_NUMBER(CHANNEL_NUMBER/2)
                ) algorithm_selector (
                    .target_i(target_i),
                    .selector_o(ctrl_logical)
                );
            end
            else begin : circulant_alg_error
                initial $error("Wrong algorithm for the topology %s! (ALGORITHM == %s)", TOPOLOGY, ALGORITHM);
            end
        end else begin : topology_error
            initial $error("Wrong topology! (TOPOLOGY == %s)", TOPOLOGY);
        end

    endgenerate

    always_comb begin
        for (int i = 0; i < CHANNEL_NUMBER; i++) begin
            out_mosi_o[i] = '0;
        end
        in_miso_o = ((in_mosi_i.data.TID != ROUTING_HEADER_READ && in_mosi_i.data.TID != ROUTING_HEADER_WRITE) || !busy[ctrl]) ?
                    out_miso_i[ctrl] : '0;
        out_mosi_o[ctrl] = ((in_mosi_i.data.TID != ROUTING_HEADER_READ && in_mosi_i.data.TID != ROUTING_HEADER_WRITE) || !busy[ctrl]) ?
                            in_mosi_i : '0;
    end

    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            busy <= '0;
        end else begin
            busy <= busy_next;
        end
    end

    always_comb begin
        busy_next = busy;
        if (in_mosi_i.TVALID && (in_mosi_i.data.TID == ROUTING_HEADER_READ || in_mosi_i.data.TID == ROUTING_HEADER_WRITE)) begin
            busy_next[ctrl] = out_miso_i[ctrl].TREADY ? 1'b1 : busy[ctrl];
        end
        else if (in_mosi_i.TVALID) begin
            if (in_mosi_i.data.TLAST && out_miso_i[ctrl].TREADY) begin
                busy_next[ctrl] = 1'b0;
            end
        end
    end

endmodule