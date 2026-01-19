module tb_axi;

    logic ACLK, ARESETn;

    logic finished = '0;

    always #10 ACLK = ~ACLK;

    `include "axi_type.svh"

    axi_miso_t axi_miso_master;
    axi_mosi_t axi_mosi_master;

    axi_miso_t axi_miso_slave[3];
    axi_mosi_t axi_mosi_slave[3];

    axi_demux #(
        .OUTPUT_NUM(3),
        .ID_ROUTING('{0, 1, 2, 3})
    ) ad (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .s_axi_i(axi_mosi_master),
        .s_axi_o(axi_miso_master),

        .m_axi_i(axi_miso_slave),
        .m_axi_o(axi_mosi_slave)
    );

    task aw_send(
        integer number,
        logic [3:0] id [$],
        integer addr [$],
        integer length [$],
        integer size [$],
        integer burst [$]
    );

        @(posedge ACLK) begin
            axi_mosi_master.AWVALID <= 1;
            axi_mosi_master.data.aw.AWID <= id[0];
            axi_mosi_master.data.aw.AWADDR <= addr[0];
            axi_mosi_master.data.aw.AWLEN <= length[0];
            axi_mosi_master.data.aw.AWSIZE <= size[0];
            axi_mosi_master.data.aw.AWBURST <= burst[0];
        end

        for (int i = 1; i < number; i++) begin
            @(posedge ACLK) begin
                while (!axi_miso_master.AWREADY) begin
                    @(posedge ACLK);
                end
                axi_mosi_master.AWVALID <= 1;
                axi_mosi_master.data.aw.AWID <= id[i];
                axi_mosi_master.data.aw.AWADDR <= addr[i];
                axi_mosi_master.data.aw.AWLEN <= length[i];
                axi_mosi_master.data.aw.AWSIZE <= size[i];
                axi_mosi_master.data.aw.AWBURST <= burst[i];
            end
        end

        @(posedge ACLK) begin
            while (!axi_miso_master.AWREADY) begin
                @(posedge ACLK);
            end
            axi_mosi_master.AWVALID <= 0;
            axi_mosi_master.data.aw.AWID <= 0;
            axi_mosi_master.data.aw.AWADDR <= 0;
            axi_mosi_master.data.aw.AWLEN <= 0;
            axi_mosi_master.data.aw.AWSIZE <= 0;
            axi_mosi_master.data.aw.AWBURST <= 0;
        end
    endtask

    task w_send(
        integer length,
        logic [31:0] wdata [$],
        logic [3:0] wstrb [$]
    );

        for (int i = 0; i < length; i++) begin
            @(posedge ACLK) begin
                while (!axi_miso_master.WREADY) begin
                    @(posedge ACLK);
                end
                axi_mosi_master.WVALID <= 1;
                axi_mosi_master.data.w.WDATA <= wdata[i];
                axi_mosi_master.data.w.WSTRB <= wstrb[i];
                if (i == length - 1) begin
                    axi_mosi_master.data.w.WLAST <= 1;
                end
            end
        end

        @(posedge ACLK) begin
            while (!axi_miso_master.WREADY) begin
                @(posedge ACLK);
            end
            axi_mosi_master.WVALID <= 0;
            axi_mosi_master.data.w.WDATA <= 0;
            axi_mosi_master.data.w.WSTRB <= 0;
            axi_mosi_master.data.w.WLAST <= 0;
        end

    endtask

    logic BVALID[3];
    logic BREADY[3];
    logic WLAST[3];
    logic WVALID[3];
    logic WREADY[3];

    generate
        for (genvar i = 0; i < 3; i++) begin
            assign axi_miso_slave[i].BVALID = BVALID[i];
            assign axi_miso_slave[i].data.b.BID = i;
            assign BREADY[i] = axi_mosi_slave[i].BREADY;
            assign WLAST[i] = axi_mosi_slave[i].data.w.WLAST;
            assign WVALID[i] = axi_mosi_slave[i].WVALID;
            assign axi_miso_slave[i].WREADY = WREADY[i];
        end
    endgenerate

    
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            for (int i = 0; i < 3; i++) begin
                BVALID[i] <= 0;
            end
        end
        else begin
            for (int i = 0; i < 3; i++) begin
                if (WREADY[i] && WVALID[i] && WLAST[i]) begin
                    BVALID[i] <= 1;
                end
                else begin
                    if (BVALID[i] && BREADY[i]) begin
                        BVALID[i] <= 0;
                    end
                end
            end
        end
    end

    initial begin

        $dumpfile("tb_axi.vcd");
        $dumpvars;

        ACLK = 1;
        ARESETn = 0;

        axi_mosi_master.AWVALID = 0;
        axi_mosi_master.data.aw.AWID = 0;
        axi_mosi_master.data.aw.AWADDR = 0;
        axi_mosi_master.data.aw.AWLEN = 0;
        axi_mosi_master.data.aw.AWSIZE = 0;
        axi_mosi_master.data.aw.AWBURST = 0;

        axi_mosi_master.WVALID = 0;
        axi_mosi_master.data.w.WDATA = 0;
        axi_mosi_master.data.w.WSTRB = 0;
        axi_mosi_master.data.w.WLAST = 0;
        
        axi_mosi_master.BREADY = 0;

        axi_miso_slave[0].AWREADY = 0;
        axi_miso_slave[1].AWREADY = 0;
        axi_miso_slave[2].AWREADY = 0;

        WREADY[0] = 0;
        WREADY[1] = 0;
        WREADY[2] = 0;

        #25;
        ARESETn = 1;

        fork
            
            for (int i = 0; i < 6; i++) begin
                w_send(
                    2,
                    '{1, 2},
                    '{4'hF, 4'hF}
                );
            end

            aw_send(
                6,
                '{0, 1, 2, 3, 4, 5},
                '{0, 4, 8, 12, 16, 20},
                '{1, 1, 1, 1, 1, 1},
                '{32, 32, 32, 32, 32, 32},
                '{1, 1, 1, 1, 1, 1}
            );

            begin
                @(posedge ACLK);
                @(posedge ACLK);
                @(posedge ACLK);
                @(posedge ACLK) begin
                    axi_miso_slave[0].AWREADY <= 1;
                    axi_miso_slave[1].AWREADY <= 1;
                    axi_miso_slave[2].AWREADY <= 1;
                    WREADY[0] <= 1;
                    WREADY[1] <= 1;
                    WREADY[2] <= 1;
                    axi_mosi_master.BREADY <= 1;
                end
            end

        join

        @(posedge ACLK);
        @(posedge ACLK);
        @(posedge ACLK);
        @(posedge ACLK);
        @(posedge ACLK);
        @(posedge ACLK);
        @(posedge ACLK);
        @(posedge ACLK);
        @(posedge ACLK);
        @(posedge ACLK);
        @(posedge ACLK);
        @(posedge ACLK);

        finished = '1;

        @(posedge ACLK);

        $finish;
        
    end

endmodule