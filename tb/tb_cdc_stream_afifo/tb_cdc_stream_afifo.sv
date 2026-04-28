module tb_cdc_stream_afifo;

parameter DATA_WIDTH = 32;
parameter FIFO_DEPTH = 16;

parameter ADDR_WIDTH = $clog2(FIFO_DEPTH);

logic [31:0] random_seed;

logic test_done;
logic error;
logic [DATA_WIDTH-1:0] read_data;
logic [DATA_WIDTH-1:0] written_data;

logic                  clk_wr  ;
logic                  rst_n_wr;

logic [DATA_WIDTH-1:0] data_i  ;
logic                  valid_i ;
logic                  ready_o ;
logic [ADDR_WIDTH:0]   free_o  ;

logic                  clk_rd  ;
logic                  rst_n_rd;

logic [DATA_WIDTH-1:0] data_o  ;
logic                  valid_o ;
logic                  ready_i ;
logic [ADDR_WIDTH:0]   count_o ;


logic [DATA_WIDTH-1:0] written [$];
logic [DATA_WIDTH-1:0] read [$];

always_ff @(posedge clk_wr) begin
    if (valid_i && ready_o) begin
        written.push_back(data_i);
    end
end

always_ff @(posedge clk_rd) begin
    if (valid_o && ready_i) begin
        read.push_back(data_o);
    end
end


cdc_stream_afifo #(
    .DATA_WIDTH (DATA_WIDTH),
    .FIFO_DEPTH (FIFO_DEPTH)
) dut (
    .clk_wr   (clk_wr  ),
    .rst_n_wr (rst_n_wr),

    .data_i   (data_i  ),
    .valid_i  (valid_i ),
    .ready_o  (ready_o ),
    .free_o   (free_o  ),

    .clk_rd   (clk_rd  ),
    .rst_n_rd (rst_n_rd),

    .data_o   (data_o  ),
    .valid_o  (valid_o ),
    .ready_i  (ready_i ),
    .count_o  (count_o )
);

always #11 clk_wr = ~clk_wr;
always #31 clk_rd = ~clk_rd;

initial begin
    test_done = 0;
    error = 0;

    clk_wr = 1;
    clk_rd = 1;
    
    rst_n_wr = '0;
    rst_n_rd = '0;

    data_i  = '0;
    valid_i = '0;
    ready_i = '0;

    #25;

    rst_n_wr = '1;
    rst_n_rd = '1;

    @(posedge clk_wr);
    for (int i = 0; i < FIFO_DEPTH; i++) begin
        data_i  = $urandom(random_seed);
        valid_i = 1;
        @(posedge clk_wr);
    end
    valid_i = 0;
    
    @(posedge clk_rd);
    while (valid_o == 1) begin
        ready_i = 1;
        @(posedge clk_rd);
    end
    ready_i = 0;
    @(posedge clk_rd);

    fork
        
        begin
            @(posedge clk_wr);
            for (int i = 0; i < 100; i++) begin
                if (valid_i && ready_o) begin
                    data_i = $urandom(random_seed);
                end
                valid_i = 1;
                @(posedge clk_wr);
            end
            valid_i = 0;
        end
        
        
        begin
            @(posedge clk_rd);
            for (int i = 0; i < 100; i++) begin
                ready_i = $urandom(random_seed);
                @(posedge clk_rd);
            end
        end

    join
    
    ready_i = 1;

    while (valid_o == 1) begin
        @(posedge clk_rd);
    end
    @(posedge clk_rd);

    assert (written.size() == read.size()) 
    else   begin
        error = 1;
        test_done = 1;
        $error("Mismatched sizes: %d written, %d read", written.size(), read.size());
    end

    while (written.size()) begin
        read_data = read.pop_front();
        written_data = written.pop_front();

        assert (read_data == written_data) 
        else   begin
            error = 1;
            test_done = 1;
            $error("Erroneous data: %x written, %x read", written_data, read_data);
        end
    end

    test_done = 1;
end
    
endmodule