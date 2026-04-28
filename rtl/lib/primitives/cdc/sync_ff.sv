module sync_ff #(
    parameter FF3        = 0, // if 0 - 2FF used, if 1 - 3FF used
    parameter DATA_WIDTH = 1
) (
    input  logic [DATA_WIDTH-1:0] data_i  ,

    input  logic                  clk_rd  ,
    input  logic                  rst_n_rd,
    output logic [DATA_WIDTH-1:0] data_o  
);

    logic [DATA_WIDTH-1:0] sync [3];

    generate
        if (FF3 == 1) begin : sync_3ff
            assign data_o = sync[2];
        end
        else begin : sync_2ff
            assign data_o = sync[1];
        end
    endgenerate

    always_ff @(posedge clk_rd or negedge rst_n_rd) begin : blockName
        if (!rst_n_rd) begin
            sync[0] <= '0;
            sync[1] <= '0;
            sync[2] <= '0;
        end
        else begin
            sync[0] <= data_i;
            sync[1] <= sync[0];
            sync[2] <= sync[1];
        end
    end
    
endmodule