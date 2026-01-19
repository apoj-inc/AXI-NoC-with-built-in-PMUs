`timescale 1ps/1ps
module tb_axi_memory;

    parameter ID_W_WIDTH = 4;
    parameter ID_R_WIDTH = 4;
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 32;
    parameter BYTE_WIDTH = 8;

    logic ACLK, ARESETn;

    logic finished = '0;

    `include "axi_type.svh"

    axi_miso_t axi_i_miso;
    axi_mosi_t axi_i_mosi;

    always #10 ACLK = ~ACLK;

    axi_ram #(
        .ID_W_WIDTH(ID_W_WIDTH),
        .ID_R_WIDTH(ID_R_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .BYTE_WIDTH(BYTE_WIDTH)
    ) axi_r (
        .clk_i(ACLK),
        .rst_n_i(ARESETn),
        .in_mosi_i(axi_i_mosi),
        .in_miso_o(axi_i_miso)
        );

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

    axi_i_mosi.data.aw.AWID = AWID;
    axi_i_mosi.data.aw.AWADDR = AWADDR;
    axi_i_mosi.data.aw.AWLEN = AWLEN;
    axi_i_mosi.data.aw.AWSIZE = AWSIZE;
    axi_i_mosi.data.aw.AWBURST = AWBURST;

    axi_i_mosi.AWVALID = 1'b1;
    @(posedge ACLK);
    if(!axi_i_miso.AWREADY) begin
        @(posedge axi_i_miso.AWREADY);
    end
    @(posedge ACLK);

    axi_i_mosi.data.aw.AWID = '0;
    axi_i_mosi.data.aw.AWADDR = '0;
    axi_i_mosi.data.aw.AWLEN = '0;
    axi_i_mosi.data.aw.AWSIZE = '0;
    axi_i_mosi.data.aw.AWBURST = '0;
    axi_i_mosi.AWVALID = '0;

    for(int i = 0; i < AWLEN+1; i++) begin
        @(posedge ACLK);
        axi_i_mosi.data.w.WLAST = i == AWLEN;
        axi_i_mosi.data.w.WDATA = WDATA[i];
        axi_i_mosi.data.w.WSTRB = WSTRB[i];
        axi_i_mosi.WVALID = 1'b1;

        if(!axi_i_miso.WREADY) begin
            @(posedge axi_i_miso.WREADY);
        end
        @(posedge ACLK);
        axi_i_mosi.data.w.WLAST = '0;
        axi_i_mosi.data.w.WDATA = '0;
        axi_i_mosi.data.w.WSTRB = '0;
        axi_i_mosi.WVALID = '0;
    end

    while(!axi_i_miso.BVALID)
        @(posedge ACLK);

    @(posedge ACLK);
    axi_i_mosi.BREADY = 1'b1;

    @(posedge ACLK);
    axi_i_mosi.BREADY = 1'b0;
    @(posedge ACLK);

    endtask : am_write

    task am_read(
        // AR channel 
        logic [ID_W_WIDTH-1:0] ARID,
        logic [ADDR_WIDTH-1:0] ARADDR,
        logic [7:0] ARLEN,
        logic [2:0] ARSIZE,
        logic [1:0] ARBURST,
        logic [AXI_DATA_WIDTH-1:0] expected_read[]
    );

    static integer read = 0;

    axi_i_mosi.data.ar.ARID = ARID;
    axi_i_mosi.data.ar.ARADDR = ARADDR;
    axi_i_mosi.data.ar.ARLEN = ARLEN;
    axi_i_mosi.data.ar.ARSIZE = ARSIZE;
    axi_i_mosi.data.ar.ARBURST = ARBURST;
    axi_i_mosi.RREADY = '0;

    axi_i_mosi.ARVALID = 1'b1;
    @(posedge ACLK);
    if(!axi_i_miso.ARREADY) begin
        @(posedge axi_i_miso.ARREADY);
    end
    @(posedge ACLK);

    axi_i_mosi.data.ar.ARID = '0;
    axi_i_mosi.data.ar.ARADDR = '0;
    axi_i_mosi.data.ar.ARLEN = '0;
    axi_i_mosi.data.ar.ARSIZE = '0;
    axi_i_mosi.data.ar.ARBURST = '0;
    axi_i_mosi.ARVALID = '0;

    while(!axi_i_miso.data.r.RLAST) begin
        while(!axi_i_miso.RVALID) @(posedge ACLK);
        axi_i_mosi.RREADY = '1;
        $display("Value %h", axi_i_miso.data.r.RDATA);
        if($size(expected_read) != 0) begin
            assert (axi_i_miso.data.r.RDATA === expected_read[read])
            else   begin
                $error("Read unexpected: expected %h, got %h", expected_read[read], axi_i_miso.data.r.RDATA);
                $finish;
            end
            read++;
        end
        @(posedge ACLK);
        axi_i_mosi.RREADY = '0;
        @(posedge ACLK);
    end

    while(!axi_i_miso.RVALID) @(posedge ACLK);
    axi_i_mosi.RREADY = '1;
    $display("Value %h", axi_i_miso.data.r.RDATA);
    if($size(expected_read) != 0) begin
        assert (axi_i_miso.data.r.RDATA === expected_read[read])
        else   begin
            $error("Read unexpected: expected %h, got %h", expected_read[read], axi_i_miso.data.r.RDATA);
            $finish;
        end
        read++;
    end
    @(posedge ACLK);
    axi_i_mosi.RREADY = '0;
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