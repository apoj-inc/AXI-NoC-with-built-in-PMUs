`timescale 1ps/1ps
module tb_axi_memory;

    parameter ID_W_WIDTH = 4;
    parameter ID_R_WIDTH = 4;
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 32;
    parameter BYTE_WIDTH = 8;

    logic ACLK, ARESETn;

    always #10 ACLK = ~ACLK;

    axi_if #(
        .ID_W_WIDTH(ID_W_WIDTH),
        .ID_R_WIDTH(ID_R_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
        ) axi_i();

    axi_ram #(
        .ID_W_WIDTH(ID_W_WIDTH),
        .ID_R_WIDTH(ID_R_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BYTE_WIDTH(BYTE_WIDTH)
    ) axi_r (.clk(ACLK), .rst_n(ARESETn), .axi_s(axi_i.s));

    task am_write(
        // AW channel 
        logic [ID_W_WIDTH-1:0] AWID,
        logic [ADDR_WIDTH-1:0] AWADDR,
        logic [7:0] AWLEN,
        logic [2:0] AWSIZE,
        logic [1:0] AWBURST,

        // W channel
        logic [DATA_WIDTH-1:0] WDATA [$],
        logic [(DATA_WIDTH/8)-1:0] WSTRB [$]

    );

    axi_i.AWID = AWID;
    axi_i.AWADDR = AWADDR;
    axi_i.AWLEN = AWLEN;
    axi_i.AWSIZE = AWSIZE;
    axi_i.AWBURST = AWBURST;

    axi_i.AWVALID = 1'b1;
    @(posedge ACLK);
    if(!axi_i.AWREADY) begin
        @(posedge axi_i.AWREADY);
    end
    @(posedge ACLK);

    axi_i.AWID = '0;
    axi_i.AWADDR = '0;
    axi_i.AWLEN = '0;
    axi_i.AWSIZE = '0;
    axi_i.AWBURST = '0;
    axi_i.AWVALID = '0;

    for(int i = 0; i < AWLEN+1; i++) begin
        @(posedge ACLK);
        axi_i.WLAST = i == AWLEN;
        axi_i.WDATA = WDATA[i];
        axi_i.WSTRB = WSTRB[i];
        axi_i.WVALID = 1'b1;

        if(!axi_i.WREADY) begin
            @(posedge axi_i.WREADY);
        end
        @(posedge ACLK);
        axi_i.WLAST = '0;
        axi_i.WDATA = '0;
        axi_i.WSTRB = '0;
        axi_i.WVALID = '0;
    end

    while(!axi_i.BVALID)
        @(posedge ACLK);

    @(posedge ACLK);
    axi_i.BREADY = 1'b1;

    @(posedge ACLK);
    axi_i.BREADY = 1'b0;
    @(posedge ACLK);

    endtask : am_write

    task am_read(
        // AR channel 
        logic [ID_W_WIDTH-1:0] ARID,
        logic [ADDR_WIDTH-1:0] ARADDR,
        logic [7:0] ARLEN,
        logic [2:0] ARSIZE,
        logic [1:0] ARBURST
    );

    axi_i.ARID = ARID;
    axi_i.ARADDR = ARADDR;
    axi_i.ARLEN = ARLEN;
    axi_i.ARSIZE = ARSIZE;
    axi_i.ARBURST = ARBURST;

    axi_i.ARVALID = 1'b1;
    @(posedge ACLK);
    if(!axi_i.ARREADY) begin
        @(posedge axi_i.ARREADY);
    end
    @(posedge ACLK);

    axi_i.ARID = '0;
    axi_i.ARADDR = '0;
    axi_i.ARLEN = '0;
    axi_i.ARSIZE = '0;
    axi_i.ARBURST = '0;
    axi_i.ARVALID = '0;

    while(!axi_i.RLAST) begin
        @(posedge axi_i.RVALID);
        @(posedge ACLK);
        axi_i.RREADY = '1;
        $display("Value %h", axi_i.RDATA);
        @(posedge ACLK);
        axi_i.RREADY = '0;
        @(posedge ACLK);
    end

    @(posedge axi_i.RVALID);
    @(posedge ACLK);
    axi_i.RREADY = '1;
    $display("Value %h", axi_i.RDATA);
    @(posedge ACLK);
    axi_i.RREADY = '0;
    @(posedge ACLK);

    endtask : am_read

    initial begin
        ACLK = 1'b0;
        ARESETn = 1'b0;
        #10
        ARESETn = 1'b1;
        fork
            begin
                am_write(
                1, // AWID
                1, // AWADDR
                2, // AWLEN
                2, // AWSIZE
                1, // AWBURST

                {32'hFFFFFFFF, 32'h89ABCDEF, 32'h01234567},
                {4'b1001, 4'hF, 4'hF}
            );
            end
            begin
                for (int i = 0; i < 6; i++) begin
                    @(posedge ACLK);
                end
                am_read(
                    1, // ARID
                    1, // ARADDR
                    2, // ARLEN
                    2, // ARSIZE
                    1 // ARBURST
                );
            $finish;
            end
            #1000 $finish;
        join
        
    end

endmodule : tb_axi_memory