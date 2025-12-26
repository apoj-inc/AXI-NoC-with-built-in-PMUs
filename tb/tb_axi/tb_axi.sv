module tb_axi;

    logic ACLK, ARESETn;

    always #10 ACLK = ~ACLK;


    axi_if master ();

    axi_if slave[3] ();

    axi_demux #(
        .OUTPUT_NUM(3),
        .ID_ROUTING('{0, 1, 2, 3})
    ) ad (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .s_axi_in(master),
        .m_axi_out(slave)
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
            master.AWVALID <= 1;
            master.AWID <= id[0];
            master.AWADDR <= addr[0];
            master.AWLEN <= length[0];
            master.AWSIZE <= size[0];
            master.AWBURST <= burst[0];
        end

        for (int i = 1; i < number; i++) begin
            @(posedge ACLK) begin
                while (!master.AWREADY) begin
                    @(posedge ACLK);
                end
                master.AWVALID <= 1;
                master.AWID <= id[i];
                master.AWADDR <= addr[i];
                master.AWLEN <= length[i];
                master.AWSIZE <= size[i];
                master.AWBURST <= burst[i];
            end
        end

        @(posedge ACLK) begin
            while (!master.AWREADY) begin
                @(posedge ACLK);
            end
            master.AWVALID <= 0;
            master.AWID <= 0;
            master.AWADDR <= 0;
            master.AWLEN <= 0;
            master.AWSIZE <= 0;
            master.AWBURST <= 0;
        end
    endtask

    task w_send(
        integer length,
        logic [31:0] wdata [$],
        logic [3:0] wstrb [$]
    );

        for (int i = 0; i < length; i++) begin
            @(posedge ACLK) begin
                while (!master.WREADY) begin
                    @(posedge ACLK);
                end
                master.WVALID <= 1;
                master.WDATA <= wdata[i];
                master.WSTRB <= wstrb[i];
                if (i == length - 1) begin
                    master.WLAST <= 1;
                end
            end
        end

        @(posedge ACLK) begin
            while (!master.WREADY) begin
                @(posedge ACLK);
            end
            master.WVALID <= 0;
            master.WDATA <= 0;
            master.WSTRB <= 0;
            master.WLAST <= 0;
        end

    endtask

    logic BVALID[3];
    logic BREADY[3];
    logic WLAST[3];
    logic WVALID[3];
    logic WREADY[3];

    generate
        for (genvar i = 0; i < 3; i++) begin
            assign slave[i].BVALID = BVALID[i];
            assign slave[i].BID = i;
            assign BREADY[i] = slave[i].BREADY;
            assign WLAST[i] = slave[i].WLAST;
            assign WVALID[i] = slave[i].WVALID;
            assign slave[i].WREADY = WREADY[i];
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

        master.AWVALID = 0;
        master.AWID = 0;
        master.AWADDR = 0;
        master.AWLEN = 0;
        master.AWSIZE = 0;
        master.AWBURST = 0;

        master.WVALID = 0;
        master.WDATA = 0;
        master.WSTRB = 0;
        master.WLAST = 0;
        
        master.BREADY = 0;

        slave[0].AWREADY = 0;
        slave[1].AWREADY = 0;
        slave[2].AWREADY = 0;

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
                    slave[0].AWREADY <= 1;
                    slave[1].AWREADY <= 1;
                    slave[2].AWREADY <= 1;
                    WREADY[0] <= 1;
                    WREADY[1] <= 1;
                    WREADY[2] <= 1;
                    master.BREADY <= 1;
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

        $finish;
        
    end

endmodule