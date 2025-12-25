module tb_arbiter;

    logic ACLK, ARESETn;
    logic [4:0] valid_i, ready_o;
    logic [15:0] data_o;
    logic valid_o, ready_i;

    always #10 ACLK = ~ACLK;

    stream_arbiter #(
        .OUTPUT_NUM(5),
        .DATA_WIDTH(16)
    ) sa (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i({'hAAAA, 'hBBBB, 'hCCCC, 'hDDDD, 'hEEEE}),
        .valid_i(valid_i),
        .ready_o(ready_o),

        .data_o(data_o),
        .valid_o(valid_o),
        .ready_i(ready_i)
    );

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            valid_i <= 0;
            ready_i <= 0;
        end
        else begin
            if (valid_i == '0) begin
                valid_i <= $urandom_range(0, 31);
            end
            else begin
                for (int i = 0; i < 5; i++) begin
                    valid_i[i] <= ((valid_i[i] == 1) && (ready_o[i] == 1)) ? 0 : valid_i[i];
                end
            end
            ready_i <= $urandom_range(0, 1);
        end
    end

    initial begin
        ACLK = 1;
        ARESETn = 0;
        #25;
        ARESETn = 1;

        for (int i = 0; i < 200; i++) begin
            @(posedge ACLK);
        end

        $finish;
    end
    
endmodule