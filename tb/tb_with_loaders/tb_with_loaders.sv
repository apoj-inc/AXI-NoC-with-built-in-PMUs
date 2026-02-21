`timescale 1ps/1ps

module tb_with_loaders #(
    parameter N = 16
) (
    input  logic        aclk,
    input  logic        aresetn,

    input  logic        pmu_enable_i,
    input  logic [4:0]  pmu_addr_i   [N],
    output logic [31:0] pmu_data_o   [N],

    input  logic        resp_wait_i  [N],
    input  logic [4:0]  id_i         [N],
    input  logic        write_i      [N],
    input  logic [7:0]  axlen_i      [N],
    input  logic        fifo_push_i  [N],
    input  logic        start_i,
    output logic        idle_o       [N]
);

    mesh_with_loaders ct (
        .aclk         (aclk),
        .aresetn      (aresetn),
 
        .pmu_enable_i (pmu_enable_i),
        .pmu_addr_i   (pmu_addr_i),
        .pmu_data_o   (pmu_data_o),
 
        .resp_wait_i  (resp_wait_i),
        .id_i         (id_i),
        .write_i      (write_i),
        .axlen_i      (axlen_i),
        .fifo_push_i  (fifo_push_i),
        .start_i      (start_i),
        .idle_o       (idle_o)
    );

endmodule
