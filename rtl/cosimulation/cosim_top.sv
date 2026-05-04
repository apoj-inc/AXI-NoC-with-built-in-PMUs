`include "defines.svh"

module cosim_top #(
    parameter        BAUD_RATE      = 10_000_000,
    parameter        CLK_FREQ       = 50_000_000,

    parameter        AXI_DATA_WIDTH = 32,
    parameter        AXI_ID_W_WIDTH = 5,
    parameter        AXI_ID_R_WIDTH = 5,
    parameter        AXI_ADDR_WIDTH = 16,

    parameter        AXIS_DATA_WIDTH = 40,
    parameter        AXIS_ID_WIDTH = 3,
    parameter        AXIS_DEST_WIDTH = 4,
    parameter        AXIS_USER_WIDTH = 4,
    
    parameter        AXI_MASTER_LOADER_FIFO_DEPTH = 64,

    parameter        MAX_ROUTERS_X = 4,
    parameter        MAX_ROUTERS_X_WIDTH = $clog2(MAX_ROUTERS_X),
    parameter        MAX_ROUTERS_Y = 4,
    parameter        MAX_ROUTERS_Y_WIDTH = $clog2(MAX_ROUTERS_Y),
    parameter        GENERATICS_COUNT = 2,
    parameter int    GENERATICS[GENERATICS_COUNT] = '{2, 1},

    parameter string TOPOLOGY = "Mesh",
    parameter string BUFFER_ALLOCATOR = "Straight",
    parameter        BUFFER_DEPTH = 16,
    parameter string ALGORITHM = "XY",

    parameter        ROUTERS_COUNT = MAX_ROUTERS_X*MAX_ROUTERS_Y,
    parameter        CORE_COUNT = ROUTERS_COUNT,
    parameter        AXI_MAX_ID_WIDTH = (AXI_ID_W_WIDTH > AXI_ID_R_WIDTH) ? AXI_ID_W_WIDTH : AXI_ID_R_WIDTH,

    parameter        SIMULTANIOUS_VIRTUAL_NETWORK_ROUTING = 1,
    parameter        VIRTUAL_NETWORK_NUMBER = 2,
    parameter        VIRTUAL_CHANNEL_NUMBER = 2,
    parameter int    VIRTUAL_NETWORKS[VIRTUAL_NETWORK_NUMBER] = '{1, 1},

    parameter        AXI_DATA_BYTES = AXI_DATA_WIDTH / 8 + (AXI_DATA_WIDTH % 8 != 0)
) (
    input  logic clk_i,
    input  logic arstn_i,
    input  logic rx_i,
    output logic tx_o
);

    logic [4:0]                  pmu_addr   [CORE_COUNT];
    logic [31:0]                 pmu_data   [CORE_COUNT];
    logic                        resp_wait  [CORE_COUNT];
    logic [AXI_MAX_ID_WIDTH-1:0] id         [CORE_COUNT];
    logic                        write      [CORE_COUNT];
    logic [AXI_ADDR_WIDTH-1:0]   axaddr     [CORE_COUNT];
    logic [7:0]                  axlen      [CORE_COUNT];
    logic [AXI_DATA_WIDTH-1:0]   wdata      [CORE_COUNT];
    logic [AXI_DATA_BYTES-1:0]   wstrb      [CORE_COUNT];
    logic                        fifo_push  [CORE_COUNT];
    logic                        start                  ;
    logic                        idle       [CORE_COUNT];
    logic [AXI_DATA_WIDTH-1:0]   rdata      [CORE_COUNT];

    logic                        rstn_noc;
    logic                        pmu_enable;

    logic [2:0]                  rx_sync;

    always_ff @(posedge clk_i or negedge arstn_i) begin
        if (!arstn_i) begin
            rx_sync <= 3'b111;
        end
        else begin
            rx_sync <= {rx_sync[1:0], rx_i};
        end
    end

    topology_with_loaders #(
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_ID_W_WIDTH(AXI_ID_W_WIDTH),
        .AXI_ID_R_WIDTH(AXI_ID_R_WIDTH),

        .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH(AXIS_ID_WIDTH),
        .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH(AXIS_USER_WIDTH),

        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
        .GENERATICS_COUNT(GENERATICS_COUNT),
        .GENERATICS(GENERATICS),

        .TOPOLOGY (TOPOLOGY),
        .BUFFER_DEPTH(BUFFER_DEPTH),
        .BUFFER_ALLOCATOR(BUFFER_ALLOCATOR),
        .ALGORITHM (ALGORITHM),
        
        .SIMULTANIOUS_VIRTUAL_NETWORK_ROUTING(SIMULTANIOUS_VIRTUAL_NETWORK_ROUTING),
        .VIRTUAL_NETWORK_NUMBER(VIRTUAL_NETWORK_NUMBER),
        .VIRTUAL_CHANNEL_NUMBER(VIRTUAL_CHANNEL_NUMBER),
        .VIRTUAL_NETWORKS(VIRTUAL_NETWORKS),

        .AXI_MASTER_LOADER_FIFO_DEPTH(AXI_MASTER_LOADER_FIFO_DEPTH)
    ) topology_with_loaders (
        .aclk         (clk_i),
        .aresetn      (rstn_noc ),
 
        .pmu_enable_i (pmu_enable),
        .pmu_addr_i   (pmu_addr ),
        .pmu_data_o   (pmu_data ),
 
        .resp_wait_i  (resp_wait),
        .id_i         (id       ),
        .write_i      (write    ),
        .axaddr_i     (axaddr   ),
        .axlen_i      (axlen    ),
        .wdata_i      (wdata    ),
        .wstrb_i      (wstrb    ),
        .fifo_push_i  (fifo_push),
        .start_i      (start    ),
        .idle_o       (idle     ),
        .rdata_o      (rdata    )
    );

    uart_control #(
        .CORE_COUNT   (CORE_COUNT  ),
        .AXI_ID_WIDTH (AXI_MAX_ID_WIDTH),
        .ADDR_WIDTH   (AXI_ADDR_WIDTH  ),
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
        .axaddr_o     (axaddr   ),
        .axlen_o      (axlen    ),
        .wdata_o      (wdata    ),
        .wstrb_o      (wstrb    ),
        .fifo_push_o  (fifo_push),
        .start_o      (start    ),
        .idle_i       (idle     ),
        .rdata_i      (rdata[0] ),
        
        .rstn_o       (rstn_noc ),
        .pmu_enable_o (pmu_enable)
    );
    
endmodule