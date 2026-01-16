module ram #(
    parameter ADDR_WIDTH  = 16,
    parameter BATCH_WIDTH = 4,
    parameter BYTE_WIDTH  = 8
) (
    input clk_i,

    // Port a 
    input  logic [ADDR_WIDTH-1:0] addr_a,
    input  logic [BYTE_WIDTH*BATCH_WIDTH-1:0] write_a,
    input  logic [BATCH_WIDTH-1:0] byte_en_a,
    input  logic write_en_a,
    output logic [BYTE_WIDTH*BATCH_WIDTH-1:0] data_a,

    // Port b
    input  logic [ADDR_WIDTH-1:0] addr_b,
    input  logic [BYTE_WIDTH*BATCH_WIDTH-1:0] write_b,
    input  logic [BATCH_WIDTH-1:0] byte_en_b,
    input  logic write_en_b,
    output logic [BYTE_WIDTH*BATCH_WIDTH-1:0] data_b
);

logic [BATCH_WIDTH-1:0][BYTE_WIDTH-1:0] ram [2**ADDR_WIDTH];

always @( posedge clk_i ) begin : ram_a
    begin
        data_a <= ram[addr_a];
        if(write_en_a) begin
            if(byte_en_a[0]) ram[addr_a][0] <= write_a[0*BYTE_WIDTH +: BYTE_WIDTH];
            if(byte_en_a[1]) ram[addr_a][1] <= write_a[1*BYTE_WIDTH +: BYTE_WIDTH];
            if(byte_en_a[2]) ram[addr_a][2] <= write_a[2*BYTE_WIDTH +: BYTE_WIDTH];
            if(byte_en_a[3]) ram[addr_a][3] <= write_a[3*BYTE_WIDTH +: BYTE_WIDTH];

            data_a <= write_a;
        end
    end
end

always @( posedge clk_i ) begin : ram_b
    begin
        data_b <= ram[addr_b];
        if(write_en_b) begin
            if(byte_en_b[0]) ram[addr_b][0] <= write_b[0*BYTE_WIDTH +: BYTE_WIDTH];
            if(byte_en_b[1]) ram[addr_b][1] <= write_b[1*BYTE_WIDTH +: BYTE_WIDTH];
            if(byte_en_b[2]) ram[addr_b][2] <= write_b[2*BYTE_WIDTH +: BYTE_WIDTH];
            if(byte_en_b[3]) ram[addr_b][3] <= write_b[3*BYTE_WIDTH +: BYTE_WIDTH];

            data_b <= write_b;
        end
    end
end

endmodule: ram
