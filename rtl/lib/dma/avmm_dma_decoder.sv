// avmm_dma_decoder.sv, s.talibov, creation datetime - 11.04.2026, 18:41
/*

Description:

AVMM DMA decoder - is a part of standard DMA block, which decodes commands for DMA CSR configuration and DMA task generation.
Reads commands from BAR[x] AVMM slave interface, has access to PCIe control register AVMM interface (for example to get data about MSI),
generates tasks to task channels using regular handshake interfaces, writes to CSRs using regular wordaddr-data interface.

Note: because of weird side effects conversions of Quartus Platform Designer thingy, slave BAR[x] AVMM interface uses word-addressing,
not byte-addressing. Keep this in mind when adapting drivers for different parametrizations of this module.

Supported BAR word sizes - 128 bits, addr sizes - 1 bits
Supported CRA word sizes - 32 bits,  addr sizes - 14 bits


Command system (128-bit):

Reads:

word-address: 0..1 - read device capabilities
read data:     127..13........................3....1.............................0............................
              | '0 | Max DMA transaction len | '0 | ~(64-bit DMA)/(128-bit DMA) | ~(64-bit BAR)/(128-bit BAR) |

Writes:

word-address: 0 - configure MSI address and data (those are read from the PCIe device CRA internally, no need to transfer any data here)
write data:    127...0
              | xxxxx |

word-address: 1 - generate read/write DMA task
write data:    127.....76.....75.....73............63......0
              | xxxxx | ~R/W | xxxx | len (bytes) | address |

*/

module avmm_dma_decoder #(
    parameter BAR_DATA_WIDTH = 128,
    parameter BAR_DATA_BYTES = BAR_DATA_WIDTH / 8,
    parameter BAR_ADDR_WIDTH = 1,
    
    parameter CRA_DATA_WIDTH = 32,
    parameter CRA_DATA_BYTES = CRA_DATA_WIDTH / 8,
    parameter CRA_ADDR_WIDTH = 14,

    parameter TX_DATA_WIDTH  = 128,
    parameter TX_BURST_WIDTH = 6,

    parameter BAR_CAPABILITY = (BAR_DATA_WIDTH == 128) ? 1 : 0,
    parameter DMA_CAPABILITY = (TX_DATA_WIDTH == 128) ? 1 : 0,
    parameter DMA_MAX_BYTES  = (2**TX_BURST_WIDTH - 1) * (TX_DATA_WIDTH / 8)
) (
    input  logic                      clk,
    input  logic                      rst_n,

    input  logic                      bar_chipselect_i,
    input  logic [BAR_DATA_BYTES-1:0] bar_byteenable_i,
    output logic [BAR_DATA_WIDTH-1:0] bar_readdata_o,
    input  logic [BAR_DATA_WIDTH-1:0] bar_writedata_i,
    input  logic                      bar_read_i,
    input  logic                      bar_write_i,
    output logic                      bar_readdatavalid_o,
    output logic                      bar_waitrequest_o,
    input  logic [BAR_ADDR_WIDTH-1:0] bar_address_i,

    output logic                      cra_chipselect_o,
    output logic [CRA_DATA_BYTES-1:0] cra_byteenable_o,
    input  logic [CRA_DATA_WIDTH-1:0] cra_readdata_i,
    output logic [CRA_DATA_WIDTH-1:0] cra_writedata_o,
    output logic                      cra_read_o,
    output logic                      cra_write_o,
    input  logic                      cra_waitrequest_i,
    output logic [CRA_ADDR_WIDTH-1:0] cra_address_o,

    output logic                      dma_task_valid_o,
    input  logic                      dma_task_ready_i,
    output logic [74:0]               dma_task_data_o,

    output logic [31:0]               csr_data_o,
    output logic [1:0]                csr_addr_o,
    output logic                      csr_we_o
);

    localparam MSI_ADDR_LO_PTR = 'h54;
    localparam MSI_ADDR_HI_PTR = 'h58;
    localparam MSI_DATA_PTR    = 'h5C;

    typedef enum logic[1:0] { 
        IDLE,
        READ_CAPABILITIES,
        CONFIGURE_MSI,
        GENERATE_DMA
    } state_t;

    state_t state, state_next;
    logic [31:0] in_state_counter, in_state_counter_next;

    logic bar_waitrequest, bar_waitrequest_next;
    logic bar_readdatavalid, bar_readdatavalid_next;

    logic cra_chipselect, cra_chipselect_next;
    logic cra_read, cra_read_next;
    logic [CRA_ADDR_WIDTH-1:0] cra_address, cra_address_next;

    logic [31:0] csr_data, csr_data_next;
    logic [2:0] csr_addr, csr_addr_next;
    logic csr_we, csr_we_next;

    logic [74:0] dma_task_valid, dma_task_valid_next;
    logic [74:0] dma_task_data, dma_task_data_next;

    assign bar_readdata_o[127:96] = '0;
    assign bar_readdata_o[95:64]  = '0;
    assign bar_readdata_o[63:32]  = '0;
    assign bar_readdata_o[31:0]   = {18'h0, 10'(DMA_MAX_BYTES), 2'h0, 1'(DMA_CAPABILITY), 1'(BAR_CAPABILITY)};
    assign bar_readdatavalid_o = bar_readdatavalid;
    assign bar_waitrequest_o = bar_waitrequest;

    assign cra_chipselect_o = cra_chipselect;
    assign cra_byteenable_o = '1;
    assign cra_writedata_o  = '0;
    assign cra_read_o       = cra_read;
    assign cra_write_o      = '0;
    assign cra_address_o    = cra_address;

    assign dma_task_valid_o = dma_task_valid;
    assign dma_task_data_o = dma_task_data;

    assign csr_data_o       = csr_data;
    assign csr_addr_o       = csr_addr;
    assign csr_we_o         = csr_we;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;

            bar_waitrequest <= '1;
            bar_readdatavalid <= '0;

            cra_chipselect <= '0;
            cra_read <= '0;
            cra_address <= '0;

            csr_data <= '0;
            csr_addr <= '0;
            csr_we <= '0;

            dma_task_valid <= '0;
            dma_task_data <= '0;

            in_state_counter <= '0;
        end
        else begin
            state <= state_next;

            bar_waitrequest <= bar_waitrequest_next;
            bar_readdatavalid <= bar_readdatavalid_next;

            cra_chipselect <= cra_chipselect_next;
            cra_read <= cra_read_next;
            cra_address <= cra_address_next;

            csr_data <= csr_data_next;
            csr_addr <= csr_addr_next;
            csr_we <= csr_we_next;

            dma_task_valid <= dma_task_valid_next;
            dma_task_data <= dma_task_data_next;

            in_state_counter <= in_state_counter_next;
        end
    end

    always_comb begin
        state_next = state;

        case (state)
            IDLE: begin
                if (bar_read_i) begin
                    state_next = READ_CAPABILITIES;
                end
                else if (bar_write_i) begin
                    case (bar_address_i)
                        1'b0: state_next = CONFIGURE_MSI;
                        1'b1: state_next = GENERATE_DMA;
                    endcase
                end
                else begin
                    state_next = state;
                end
            end
            READ_CAPABILITIES: begin
                if (in_state_counter == 0) begin
                    state_next = IDLE;
                end
                else begin
                    state_next = state;
                end
            end
            CONFIGURE_MSI: begin
                if (in_state_counter == 0) begin
                    state_next = IDLE;
                end
                else begin
                    state_next = state;
                end
            end
            GENERATE_DMA: begin
                if (in_state_counter == 0) begin
                    state_next = IDLE;
                end
                else begin
                    state_next = state;
                end
            end
            default: begin
            end
        endcase
    end

    always_comb begin
        bar_waitrequest_next = bar_waitrequest;
        bar_readdatavalid_next = bar_readdatavalid;

        cra_chipselect_next = cra_chipselect;
        cra_read_next = cra_read;
        cra_address_next = cra_address;

        csr_data_next = csr_data;
        csr_addr_next = csr_addr;
        csr_we_next = csr_we;
        
        dma_task_valid_next = dma_task_valid;
        dma_task_data_next = dma_task_data;

        in_state_counter_next = in_state_counter;

        case (state)
            IDLE: begin
                bar_waitrequest_next = '1;
                bar_readdatavalid_next = '0;

                cra_chipselect_next = '0;
                cra_read_next = '0;

                csr_we_next = '0;
                
                if (bar_read_i) begin
                    bar_waitrequest_next = '0;

                    in_state_counter_next = 32'd1;
                end
                else if (bar_write_i) begin
                    case (bar_address_i)
                        1'b0: begin
                            bar_waitrequest_next = '1;

                            cra_chipselect_next = '1;
                            cra_read_next = '1;
                            cra_address_next = MSI_ADDR_LO_PTR;

                            in_state_counter_next = 32'd3;
                        end
                        1'b1: begin
                            dma_task_valid_next = '1;
                            dma_task_data_next = {bar_writedata_i[76], bar_writedata_i[73:0]};

                            in_state_counter_next = 32'd1;
                        end
                    endcase
                end
            end
            READ_CAPABILITIES: begin
                bar_waitrequest_next = '1;
                case (in_state_counter)
                    32'd1: begin
                        bar_readdatavalid_next = '1;
                        in_state_counter_next = '0;
                    end
                    32'd0: begin
                        bar_readdatavalid_next = '0;
                    end
                endcase
            end
            CONFIGURE_MSI: begin
                case (in_state_counter)
                    32'd3: begin
                        if (!cra_waitrequest_i) begin
                            cra_address_next = MSI_ADDR_HI_PTR;

                            csr_data_next = cra_readdata_i;
                            csr_addr_next = 2'd0;
                            csr_we_next = '1;

                            in_state_counter_next = in_state_counter - 1;
                        end
                    end
                    32'd2: begin
                        csr_we_next = '0;
                        if (!cra_waitrequest_i) begin
                            cra_address_next = MSI_DATA_PTR;

                            csr_data_next = cra_readdata_i;
                            csr_addr_next = 2'd1;
                            csr_we_next = '1;

                            in_state_counter_next = in_state_counter - 1;
                        end
                    end
                    32'd1: begin
                        csr_we_next = '0;
                        if (!cra_waitrequest_i) begin
                            bar_waitrequest_next = '0;

                            cra_chipselect_next = '0;
                            cra_read_next = '0;

                            csr_data_next = cra_readdata_i;
                            csr_addr_next = 2'd2;
                            csr_we_next = '1;

                            in_state_counter_next = in_state_counter - 1;
                        end
                    end
                    32'd0: begin
                        csr_addr_next = 2'd3;
                        csr_we_next = '1;
                    end
                    default: begin
                    end
                endcase
            end
            GENERATE_DMA: begin
                case (in_state_counter)
                    32'd1: begin
                        if (dma_task_valid_o && dma_task_ready_i) begin
                            bar_waitrequest_next = '0;
                            dma_task_valid_next = '0;
                            in_state_counter_next = '0;
                        end
                    end
                    32'd0: begin
                        bar_waitrequest_next = '1;
                    end
                endcase
            end
            default: begin
            end
        endcase
    end
    
endmodule