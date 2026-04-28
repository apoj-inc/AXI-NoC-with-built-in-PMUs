module dual_clock_memory #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 6
) (
    input  logic                  clk_wr    ,
    input  logic                  we_i      ,
    input  logic [ADDR_WIDTH-1:0] wraddr_i  ,
    input  logic [DATA_WIDTH-1:0] wrdata_i  ,

    input  logic                  clk_rd    ,
    input  logic [ADDR_WIDTH-1:0] rdaddr_i  ,
    output logic [DATA_WIDTH-1:0] rddata_o  
);

    // Declare the RAM variable
    logic [DATA_WIDTH-1:0] ram [2**ADDR_WIDTH-1:0];
    
    always @ (posedge clk_rd) begin
        rddata_o <= ram[rdaddr_i];
    end
    
    always @ (posedge clk_wr) begin
        if (we_i) ram[wraddr_i] <= wrdata_i;
    end

endmodule