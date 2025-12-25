`timescale 1ps/1ps

`define SIM

module tb;

reg clk = 0;
reg rst_n = 0;

reg rx = 1;
wire tx;

wire clkRx, clkTx;

always #10 clk = ~clk;

toplevel dut (
    .clk(clk), .rst_n(rst_n),
    .rx(rx), .tx(tx),
    .clkRx(clkRx), .clkTx(clkTx)
);

task giveDestination (
    input logic [7:0] peekID,
    input logic [31:0] peekAddress
);

    integer i, j;

    logic [39:0] data;
    data = {peekID, peekAddress};

    for (i = 0; i < 5; i = i + 1) begin
        @(posedge clkTx) begin
            rx = 1'b0;
        end
        for (j = 0; j < 8; j = j + 1) begin
            @(posedge clkTx) begin
                rx = data[i*8 + j];
            end
        end 
        @(posedge clkTx) begin
            rx = 1'b1;
        end
    end
    
endtask

always begin

    integer i;
    for (i = 572; i < 617; i = i + 1) begin
        giveDestination(8'd3, i);
        #500_000;
    end
    
end


initial begin
    #20;
    rst_n = 1;
    #5000000;
    $stop;
end
    
endmodule