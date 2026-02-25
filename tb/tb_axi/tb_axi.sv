module tb_axi;

    logic ACLK, ARESETn;

    logic finished = '0;

    always #10 ACLK = ~ACLK;


    axi_if #(
        .AXI_DATA_WIDTH(32),
        .AXI_ADDR_WIDTH(16),
        .AXI_ID_W_WIDTH(4),
        .AXI_ID_R_WIDTH(4)
    ) axi_in(), axi_out[3]();

    axi_demux #(
        .AXI_ADDR_WIDTH(12),
        .OUTPUT_NUM(3),
        .ID_ROUTING('{0, 1, 2, 3})
    ) ad (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .s_axi_if_i(axi_in),
        .m_axi_if_o(axi_out)
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
            axi_in.AWVALID <= 1;
            axi_in.AWID <= id[0];
            axi_in.AWADDR <= addr[0];
            axi_in.AWLEN <= length[0];
            axi_in.AWSIZE <= size[0];
            axi_in.AWBURST <= burst[0];
        end

        for (int i = 1; i < number; i++) begin
            @(posedge ACLK) begin
                while (!axi_in.AWREADY) begin
                    @(posedge ACLK);
                end
                axi_in.AWVALID <= 1;
                axi_in.AWID <= id[i];
                axi_in.AWADDR <= addr[i];
                axi_in.AWLEN <= length[i];
                axi_in.AWSIZE <= size[i];
                axi_in.AWBURST <= burst[i];
            end
        end

        @(posedge ACLK) begin
            while (!axi_in.AWREADY) begin
                @(posedge ACLK);
            end
            axi_in.AWVALID <= 0;
            axi_in.AWID <= 0;
            axi_in.AWADDR <= 0;
            axi_in.AWLEN <= 0;
            axi_in.AWSIZE <= 0;
            axi_in.AWBURST <= 0;
        end
    endtask

    task w_send(
        integer length,
        logic [31:0] wdata [$],
        logic [3:0] wstrb [$]
    );

        for (int i = 0; i < length; i++) begin
            @(posedge ACLK) begin
                while (!axi_in.WREADY) begin
                    @(posedge ACLK);
                end
                axi_in.WVALID <= 1;
                axi_in.WDATA <= wdata[i];
                axi_in.WSTRB <= wstrb[i];
                if (i == length - 1) begin
                    axi_in.WLAST <= 1;
                end
            end
        end

        @(posedge ACLK) begin
            while (!axi_in.WREADY) begin
                @(posedge ACLK);
            end
            axi_in.WVALID <= 0;
            axi_in.WDATA <= 0;
            axi_in.WSTRB <= 0;
            axi_in.WLAST <= 0;
        end

    endtask

    logic BVALID[3];
    logic BREADY[3];
    logic WLAST[3];
    logic WVALID[3];
    logic WREADY[3];

    generate
        for (genvar i = 0; i < 3; i++) begin
            assign axi_out[i].BVALID = BVALID[i];
            assign axi_out[i].BID = i;
            assign BREADY[i] = axi_out[i].BREADY;
            assign WLAST[i] = axi_out[i].WLAST;
            assign WVALID[i] = axi_out[i].WVALID;
            assign axi_out[i].WREADY = WREADY[i];
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

        axi_in.AWVALID = 0;
        axi_in.AWID = 0;
        axi_in.AWADDR = 0;
        axi_in.AWLEN = 0;
        axi_in.AWSIZE = 0;
        axi_in.AWBURST = 0;

        axi_in.WVALID = 0;
        axi_in.WDATA = 0;
        axi_in.WSTRB = 0;
        axi_in.WLAST = 0;
        
        axi_in.BREADY = 0;

        axi_out[0].AWREADY = 0;
        axi_out[1].AWREADY = 0;
        axi_out[2].AWREADY = 0;

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
                    axi_out[0].AWREADY <= 1;
                    axi_out[1].AWREADY <= 1;
                    axi_out[2].AWREADY <= 1;
                    WREADY[0] <= 1;
                    WREADY[1] <= 1;
                    WREADY[2] <= 1;
                    axi_in.BREADY <= 1;
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