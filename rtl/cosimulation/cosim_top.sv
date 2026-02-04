module cosim_top #(
    parameter CORE_COUNT    = 16,
    parameter AXI_ID_WIDTH  = 5,
    parameter BAUD_RATE     = 10_000_000,
    parameter CLK_FREQ      = 50_000_000,
    parameter ADDR_WIDTH    = 16
) (
    input  logic clk_i,
    input  logic arstn_i,
    input  logic rx_i,
    output logic tx_o
);

    logic [4:0]              pmu_addr   [CORE_COUNT];
    logic [31:0]             pmu_data   [CORE_COUNT];
    logic                    resp_wait  [CORE_COUNT];
    logic [AXI_ID_WIDTH-1:0] id         [CORE_COUNT];
    logic                    write      [CORE_COUNT];
    logic [7:0]              axlen      [CORE_COUNT];
    logic                    fifo_push  [CORE_COUNT];
    logic                    start                  ;
    logic                    idle       [CORE_COUNT];

    logic                    rstn_noc;
    logic                    pmu_enable;

    logic [2:0]              rx_sync;

    always_ff @(posedge clk_i or negedge arstn_i) begin
        if (!arstn_i) begin
            rx_sync <= 3'b111;
        end
        else begin
            rx_sync <= {rx_sync[1:0], rx_i};
        end
    end

    mesh_with_loaders #(
        .ADDR_WIDTH   (ADDR_WIDTH)
    ) mesh_with_loaders (
        .aclk         (clk_i),
        .aresetn      (rstn_noc ),
 
        .pmu_enable_i (pmu_enable),
        .pmu_addr_i   (pmu_addr ),
        .pmu_data_o   (pmu_data ),
 
        .resp_wait_i  (resp_wait),
        .id_i         (id       ),
        .write_i      (write    ),
        .axlen_i      (axlen    ),
        .fifo_push_i  (fifo_push),
        .start_i      (start    ),
        .idle_o       (idle     )
    );

    uart_control #(
        .CORE_COUNT   (CORE_COUNT  ),
        .AXI_ID_WIDTH (AXI_ID_WIDTH),
        .BAUD_RATE    (BAUD_RATE   ),
        .CLK_FREQ     (CLK_FREQ    )
    ) uart_control (
        .clk_i        (clk_i),
        .arstn_i      (arstn_i),
        .rx_i         (rx_sync[2]),
        .tx_o         (tx_o),

        .pmu_addr_o   (pmu_addr ),
        .pmu_data_i   (pmu_data ),

        .resp_wait_o  (resp_wait),
        .id_o         (id       ),
        .write_o      (write    ),
        .axlen_o      (axlen    ),
        .fifo_push_o  (fifo_push),
        .start_o      (start    ),
        .idle_i       (idle     ),
        
        .rstn_o       (rstn_noc ),
        .pmu_enable_o (pmu_enable)
    );
    
endmodule