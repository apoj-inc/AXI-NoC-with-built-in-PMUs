module avmm_dma_csr (
    input  logic        clk,
    input  logic        rst_n,
    
    input  logic [31:0] csr_data_i,
    input  logic [1:0]  csr_addr_i,
    input  logic        csr_we_i,

    output logic        csr_dma_msi_set_o,
    output logic [63:0] csr_dma_msi_addr_o,
    output logic [31:0] csr_dma_msi_data_o
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            csr_dma_msi_set_o <= '0;
            csr_dma_msi_addr_o <= '0;
            csr_dma_msi_data_o <= '0;
        end
        else begin
            case (csr_addr_i)
                2'd0: begin
                    csr_dma_msi_addr_o[31:0] <= csr_data_i;
                end
                2'd1: begin
                    csr_dma_msi_addr_o[63:32] <= csr_data_i;
                end
                2'd2: begin
                    csr_dma_msi_data_o <= csr_data_i;
                end
                2'd3: begin
                    csr_dma_msi_set_o <= 1;
                end
                default: begin
                end
            endcase
        end
    end


    
endmodule