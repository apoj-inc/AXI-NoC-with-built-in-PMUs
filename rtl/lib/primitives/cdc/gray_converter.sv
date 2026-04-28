module gray_converter #(
    parameter TO_GRAY    = 0 ,
    parameter DATA_WIDTH = 32
) (
    input  logic [DATA_WIDTH-1:0] data_i,
    output logic [DATA_WIDTH-1:0] data_o
);

    generate
        if (TO_GRAY) begin : to_gray
            assign data_o = data_i ^ (data_i >> 1);
        end
        else begin : to_bin
            genvar i;
            for (i = 0; i < DATA_WIDTH; i++) begin : to_bin_bits
                assign data_o[i] = ^(data_i >> i);
            end
        end
    endgenerate
    
endmodule