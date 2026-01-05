module ram #(
    parameter ADDR_WIDTH  = 16,
    parameter BATCH_WIDTH = 4,
    parameter BYTE_WIDTH  = 8
) (
    input clk_a, clk_b,

    // Port a 
    input  logic [ADDR_WIDTH-1:0] addr_a,
    input  logic [BYTE_WIDTH*BATCH_WIDTH-1:0] write_a,
    input  logic [BYTE_WIDTH-1:0] byte_en_a,
    input  logic write_en_a,
    output logic [BYTE_WIDTH*BATCH_WIDTH-1:0] data_a,

    // Port b
    input  logic [ADDR_WIDTH-1:0] addr_b,
    input  logic [BYTE_WIDTH*BATCH_WIDTH-1:0] write_b,
    input  logic [BYTE_WIDTH-1:0] byte_en_b,
    input  logic write_en_b,
    output logic [BYTE_WIDTH*BATCH_WIDTH-1:0] data_b
);

logic [BYTE_WIDTH-1:0][BATCH_WIDTH-1:0] ram [2**ADDR_WIDTH];

always @( posedge clk_a ) begin : mem_a
    begin
        if(write_en_a) begin
            ram[addr_a] = write_a;

            if(byte_en_a[0]) mem[addr_a][0] <= wb_dat_i[0*BYTE_WIDTH +: BYTE_WIDTH];
            if(byte_en_a[1]) mem[addr_a][1] <= wb_dat_i[1*BYTE_WIDTH +: BYTE_WIDTH];
            if(byte_en_a[2]) mem[addr_a][2] <= wb_dat_i[2*BYTE_WIDTH +: BYTE_WIDTH];
            if(byte_en_a[3]) mem[addr_a][3] <= wb_dat_i[3*BYTE_WIDTH +: BYTE_WIDTH];

        end
        data_a <= ram[addr_a];
    end
end

always @( posedge clk_b ) begin : mem_b
    begin
        if(write_en_b) begin
            ram[addr_b] = write_b;

            if(byte_en_b[0]) mem[addr_b][0] <= wb_dat_i[0*BYTE_WIDTH +: BYTE_WIDTH];
            if(byte_en_b[1]) mem[addr_b][1] <= wb_dat_i[1*BYTE_WIDTH +: BYTE_WIDTH];
            if(byte_en_b[2]) mem[addr_b][2] <= wb_dat_i[2*BYTE_WIDTH +: BYTE_WIDTH];
            if(byte_en_b[3]) mem[addr_b][3] <= wb_dat_i[3*BYTE_WIDTH +: BYTE_WIDTH];

        end
        data_b <= ram[addr_b];
    end
end
    
endmodule