module cdc_stream_afifo #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4 ,

    parameter FIFO_DEPTH = 2**ADDR_WIDTH
) (
    input  logic                  clk_wr  ,
    input  logic                  rst_n_wr,

    input  logic [DATA_WIDTH-1:0] data_i  ,
    input  logic                  valid_i ,
    output logic                  ready_o ,
    output logic [ADDR_WIDTH:0]   free_o  ,

    input  logic                  clk_rd  ,
    input  logic                  rst_n_rd,

    output logic [DATA_WIDTH-1:0] data_o  ,
    output logic                  valid_o ,
    input  logic                  ready_i ,
    output logic [ADDR_WIDTH:0]   count_o 
);

    logic [ADDR_WIDTH:0] wr_ptr        , rd_ptr        ;
    logic [ADDR_WIDTH:0] wr_gray       , rd_gray       ;
    logic [ADDR_WIDTH:0] wr_gray_resync, rd_gray_resync;
    logic [ADDR_WIDTH:0] wr_resync     , rd_resync     ;

    assign valid_o = rd_ptr != (wr_resync);
    assign ready_o = !((wr_ptr[ADDR_WIDTH] != rd_resync[ADDR_WIDTH]) & (wr_ptr[ADDR_WIDTH-1:0] == rd_resync[ADDR_WIDTH-1:0]));
    assign free_o  = FIFO_DEPTH - (wr_ptr - rd_resync);
    assign count_o = wr_resync - rd_ptr;

    gray_converter #(
        .TO_GRAY    (1           ),
        .DATA_WIDTH (ADDR_WIDTH+1)
    ) u_gray_converter_to_rd_gray (
        .data_i (wr_ptr ),
        .data_o (wr_gray)
    );
    sync_ff #(
        .FF3        (0           ),
        .DATA_WIDTH (ADDR_WIDTH+1)
    ) u_sync_ff_to_rd (
        .data_i   (wr_gray       ),

        .clk_rd   (clk_rd        ),
        .rst_n_rd (rst_n_rd      ),
        .data_o   (wr_gray_resync)
    );
    gray_converter #(
        .TO_GRAY    (0           ),
        .DATA_WIDTH (ADDR_WIDTH+1)
    ) u_gray_converter_to_rd_bin (
        .data_i (wr_gray_resync),
        .data_o (wr_resync     )
    );
    

    gray_converter #(
        .TO_GRAY    (1           ),
        .DATA_WIDTH (ADDR_WIDTH+1)
    ) u_gray_converter_to_wr_gray (
        .data_i (rd_ptr ),
        .data_o (rd_gray)
    );
    sync_ff #(
        .FF3        (0           ),
        .DATA_WIDTH (ADDR_WIDTH+1)
    ) u_sync_ff_to_wr (
        .data_i   (rd_gray       ),

        .clk_rd   (clk_wr        ),
        .rst_n_rd (rst_n_wr      ),
        .data_o   (rd_gray_resync)
    );
    gray_converter #(
        .TO_GRAY    (0           ),
        .DATA_WIDTH (ADDR_WIDTH+1)
    ) u_gray_converter_to_wr_bin (
        .data_i (rd_gray_resync),
        .data_o (rd_resync     )
    );


    dual_clock_memory #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_dual_clock_memory (
        .clk_wr   (clk_wr                                       ),
        .we_i     (valid_i & ready_o                            ),
        .wraddr_i (wr_ptr[ADDR_WIDTH-1:0]                       ),
        .wrdata_i (data_i                                       ),

        .clk_rd   (clk_rd                                       ),
        .rdaddr_i (rd_ptr[ADDR_WIDTH-1:0] + (valid_o && ready_i)),
        .rddata_o (data_o                                       )
    );

    always_ff @(posedge clk_rd or negedge rst_n_rd) begin
        if (!rst_n_rd) begin
            rd_ptr   <= '0;
        end
        else begin
            if (valid_o && ready_i) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    always_ff @(posedge clk_wr or negedge rst_n_wr) begin
        if (!rst_n_wr) begin
            wr_ptr   <= '0;
        end
        else begin
            if (valid_i && ready_o) begin
                wr_ptr <= wr_ptr + 1;
            end
        end
    end

endmodule