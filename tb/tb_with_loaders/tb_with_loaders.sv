module tb_with_loaders #(
    parameter ID_W_WIDTH = 5,
    parameter ID_R_WIDTH = 5,
    parameter MAX_ID_WIDTH = 4,
    parameter ADDR_WIDTH = 16,

    parameter N = (ID_W_WIDTH-1)*(ID_R_WIDTH-1),

    parameter AXI_DATA_WIDTH = 32
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
    input  logic        aclk,
    input  logic        aresetn,

    input  logic [4:0]  pmu_addr_i   [N],
    output logic [63:0] pmu_data_o   [N],

    input  logic [7:0]  req_depth_i,
    input  logic [4:0]  id_i         [N],
    input  logic        write_i      [N],
    input  logic [7:0]  axlen_i      [N],
    input  logic        fifo_push_i  [N],
    input  logic        start_i,
    output logic        idle_o       [N]
);

mesh_with_loaders ct(
    .aclk(aclk),
    .aresetn(aresetn),
    .pmu_addr_i(pmu_addr_i),
    .pmu_data_o(pmu_data_o),

    .req_depth_i(req_depth_i),
    .id_i(id_i),
    .write_i(write_i),
    .axlen_i(axlen_i),
    .fifo_push_i(fifo_push_i),
    .start_i(start_i),
    .idle_o(idle_o)
);

endmodule
