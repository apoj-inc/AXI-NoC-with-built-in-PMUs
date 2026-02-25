`timescale 1ps/1ps
module tb_axi_memory;

    parameter ID_W_WIDTH = 4;
    parameter ID_R_WIDTH = 4;
    parameter AXI_ADDR_WIDTH = 12;
    parameter AXI_DATA_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter BYTE_WIDTH = 8;

    logic ACLK, ARESETn;

    logic finished = '0;

    always #10 ACLK = ~ACLK;

    axi_if #(
        .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
        .AXI_ID_W_WIDTH (ID_W_WIDTH),
        .AXI_ID_R_WIDTH (ID_R_WIDTH)
    ) axi_if();

    axi_ram #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH)
    ) axi_r (
        .clk_i(ACLK),
        .rst_n_i(ARESETn),
        .s_axi_i(axi_if)
    );

    task am_write(
        // AW channel 
        logic [ID_W_WIDTH-1:0] AWID,
        logic [AXI_ADDR_WIDTH-1:0] AWADDR,
        logic [7:0] AWLEN,
        logic [2:0] AWSIZE,
        logic [1:0] AWBURST,

        // W channel
        logic [DATA_WIDTH-1:0] WDATA [$],
        logic [(DATA_WIDTH/8)-1:0] WSTRB [$]

    );

    axi_if.AWID = AWID;
    axi_if.AWADDR = AWADDR;
    axi_if.AWLEN = AWLEN;
    axi_if.AWSIZE = AWSIZE;
    axi_if.AWBURST = AWBURST;

    axi_if.AWVALID = 1'b1;
    @(posedge ACLK);
    if(!axi_if.AWREADY) begin
        @(posedge axi_if.AWREADY);
    end
    @(posedge ACLK);

    axi_if.AWID = '0;
    axi_if.AWADDR = '0;
    axi_if.AWLEN = '0;
    axi_if.AWSIZE = '0;
    axi_if.AWBURST = '0;
    axi_if.AWVALID = '0;

    for(int i = 0; i < AWLEN+1; i++) begin
        @(posedge ACLK);
        axi_if.WLAST = i == AWLEN;
        axi_if.WDATA = WDATA[i];
        axi_if.WSTRB = WSTRB[i];
        axi_if.WVALID = 1'b1;

        if(!axi_if.WREADY) begin
            @(posedge axi_if.WREADY);
        end
        @(posedge ACLK);
        axi_if.WLAST = '0;
        axi_if.WDATA = '0;
        axi_if.WSTRB = '0;
        axi_if.WVALID = '0;
    end

    while(!axi_if.BVALID)
        @(posedge ACLK);

    @(posedge ACLK);
    axi_if.BREADY = 1'b1;

    @(posedge ACLK);
    axi_if.BREADY = 1'b0;
    @(posedge ACLK);

    endtask : am_write

    task am_read(
        // AR channel 
        logic [ID_W_WIDTH-1:0] ARID,
        logic [AXI_ADDR_WIDTH-1:0] ARADDR,
        logic [7:0] ARLEN,
        logic [2:0] ARSIZE,
        logic [1:0] ARBURST,
        logic [AXI_DATA_WIDTH-1:0] expected_read[]
    );

    static integer read = 0;

    axi_if.ARID = ARID;
    axi_if.ARADDR = ARADDR;
    axi_if.ARLEN = ARLEN;
    axi_if.ARSIZE = ARSIZE;
    axi_if.ARBURST = ARBURST;
    axi_if.RREADY = '0;

    axi_if.ARVALID = 1'b1;
    @(posedge ACLK);
    if(!axi_if.ARREADY) begin
        @(posedge axi_if.ARREADY);
    end
    @(posedge ACLK);

    axi_if.ARID = '0;
    axi_if.ARADDR = '0;
    axi_if.ARLEN = '0;
    axi_if.ARSIZE = '0;
    axi_if.ARBURST = '0;
    axi_if.ARVALID = '0;

    while(!axi_if.RLAST) begin
        while(!axi_if.RVALID) @(posedge ACLK);
        axi_if.RREADY = '1;
        $display("Value %h", axi_if.RDATA);
        if($size(expected_read) != 0) begin
            assert (axi_if.RDATA === expected_read[read])
            else   begin
                $error("Read unexpected: expected %h, got %h", expected_read[read], axi_if.RDATA);
                $finish;
            end
            read++;
        end
        @(posedge ACLK);
        axi_if.RREADY = '0;
        @(posedge ACLK);
    end

    while(!axi_if.RVALID) @(posedge ACLK);
    axi_if.RREADY = '1;
    $display("Value %h", axi_if.RDATA);
    if($size(expected_read) != 0) begin
        assert (axi_if.RDATA === expected_read[read])
        else   begin
            $error("Read unexpected: expected %h, got %h", expected_read[read], axi_if.RDATA);
            $finish;
        end
        read++;
    end
    @(posedge ACLK);
    axi_if.RREADY = '0;
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
                    1, // ARBURST
                    .expected_read({32'hFFxxxxFF, 32'h89ABCDEF, 32'h01234567})
                );
            end
        join
        
        finished = '1;
        @(posedge ACLK);
        $finish;
        
    end

endmodule : tb_axi_memory