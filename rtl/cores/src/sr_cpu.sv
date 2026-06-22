/*
 * schoolRISCV - small RISC-V CPU 
 *
 * originally based on Sarah L. Harris MIPS CPU 
 *                   & schoolMIPS project
 * 
 * Copyright(c) 2017-2020 Stanislav Zhelnio 
 *                        Aleksandr Romanov 
 */ 
 
`include "sr_cpu.vh"

module sr_cpu
(
    input   logic         clk,        // clock
    input   logic         rst_n,      // reset
    input   logic [ 4:0]  regAddr,    // debug access reg address
    output  logic [31:0]  regData,    // debug access reg data
    output  logic [31:0]  imAddr,     // instruction memory address
    input   logic [31:0]  imData,     // instruction memory data

    output  logic         mem_wr_o,
    output  logic [15:0]  mem_addr_o,
    output  logic         mem_req_valid_o,
    input   logic         mem_req_ready_i,
    output  logic         mem_resp_ready_o,
    input   logic         mem_resp_valid_i,
    output  logic [31:0]  mem_wdata_o,
    input   logic [31:0]  mem_rdata_i
);

    //control wires
    wire        aluZero;
    wire        pcSrc;
    wire        regWrite;
    wire  [1:0] aluSrc;
    wire  [1:0] wdSrc;
    wire  [2:0] aluControl;

    //instruction decode wires
    wire [ 6:0] cmdOp;
    wire [ 4:0] rd;
    wire [ 2:0] cmdF3;
    wire [ 4:0] rs1;
    wire [ 4:0] rs2;
    wire [ 6:0] cmdF7;
    wire [31:0] immI;
    wire [31:0] immB;
    wire [31:0] immU;
    wire [31:0] immS;

    //program counter
    wire [31:0] pc;
    wire [31:0] pcBranch = pc + immB;
    wire [31:0] pcPlus4  = pc + 4;
    wire [31:0] pcNext   = pcSrc ? pcBranch : pcPlus4;

    logic pc_we;

    sm_register_we r_pc(clk, rst_n, pc_we, pcNext, pc);

    //program memory access
    assign imAddr = pc >> 2;
    wire [31:0] instr = imData;

    //instruction decode
    sr_decode id (
        .instr      ( instr        ),
        .cmdOp      ( cmdOp        ),
        .rd         ( rd           ),
        .cmdF3      ( cmdF3        ),
        .rs1        ( rs1          ),
        .rs2        ( rs2          ),
        .cmdF7      ( cmdF7        ),
        .immI       ( immI         ),
        .immB       ( immB         ),
        .immU       ( immU         ),
        .immS       ( immS         )
    );

    //register file
    wire [31:0] rd0;
    wire [31:0] rd1;
    wire [31:0] rd2;
    wire [31:0] wd3;

    assign mem_resp_ready_o = 1;
    assign mem_wdata_o      = rd2;

    sm_register_file rf (
        .clk        ( clk          ),
        .rst_n      ( rst_n        ),
        .a0         ( regAddr      ),
        .a1         ( rs1          ),
        .a2         ( rs2          ),
        .a3         ( rd           ),
        .rd0        ( rd0          ),
        .rd1        ( rd1          ),
        .rd2        ( rd2          ),
        .wd3        ( wd3          ),
        .we3        ( regWrite     )
    );

    //debug register access
    assign regData = (regAddr != 0) ? rd0 : pc;

    //alu
    wire [31:0] srcB = (aluSrc == 2'b00) ? rd2 :
                       (aluSrc == 2'b01) ? immI : immS;
    wire [31:0] aluResult;

    sr_alu alu (
        .srcA       ( rd1          ),
        .srcB       ( srcB         ),
        .oper       ( aluControl   ),
        .zero       ( aluZero      ),
        .result     ( aluResult    ) 
    );

    assign wd3 = (wdSrc == 2'b00) ? aluResult :
                 (wdSrc == 2'b01) ? immU : mem_rdata_i;
    assign mem_addr_o = aluResult;

    //control
    sr_control sm_control (
        .clk              ( clk              ),
        .rst_n            ( rst_n            ),

        .cmdOp            ( cmdOp            ),
        .cmdF3            ( cmdF3            ),
        .cmdF7            ( cmdF7            ),
        .aluZero          ( aluZero          ),
        .mem_resp_valid_i ( mem_resp_valid_i ),
        .mem_req_ready_i  ( mem_req_ready_i  ),
        .pc_we            ( pc_we            ),
        .pcSrc            ( pcSrc            ),
        .regWrite         ( regWrite         ),
        .aluSrc           ( aluSrc           ),
        .wdSrc            ( wdSrc            ),
        .aluControl       ( aluControl       ),
        .mem_req_valid_o  ( mem_req_valid_o  ),
        .mem_wr_o         ( mem_wr_o         )
    );

endmodule

module sr_decode
(
    input      [31:0] instr,
    output     [ 6:0] cmdOp,
    output     [ 4:0] rd,
    output     [ 2:0] cmdF3,
    output     [ 4:0] rs1,
    output     [ 4:0] rs2,
    output     [ 6:0] cmdF7,
    output reg [31:0] immI,
    output reg [31:0] immB,
    output reg [31:0] immU,
    output reg [31:0] immS
);
    assign cmdOp = instr[ 6: 0];
    assign rd    = instr[11: 7];
    assign cmdF3 = instr[14:12];
    assign rs1   = instr[19:15];
    assign rs2   = instr[24:20];
    assign cmdF7 = instr[31:25];

    // I-immediate
    always @ (*) begin
        immI[10: 0] = instr[30:20];
        immI[31:11] = { 21 {instr[31]} };
    end

    // B-immediate
    always @ (*) begin
        immB[    0] = 1'b0;
        immB[ 4: 1] = instr[11:8];
        immB[10: 5] = instr[30:25];
        immB[   11] = instr[7];
        immB[31:12] = { 20 {instr[31]} };
    end

    // U-immediate
    always @ (*) begin
        immU[11: 0] = 12'b0;
        immU[31:12] = instr[31:12];
    end

    // S-immediate
    always @ (*) begin
        immS[31: 12] = { 20 {instr[31]} };
        immS[11: 5] = instr[31:25];
        immS[4:0] = instr[11:7];
    end

endmodule

module sr_control
(
    input            clk,
    input            rst_n,

    input     [ 6:0] cmdOp,
    input     [ 2:0] cmdF3,
    input     [ 6:0] cmdF7,
    input            aluZero,
    input            mem_resp_valid_i,
    input            mem_req_ready_i,
    output           pcSrc, 
    output reg       pc_we,
    output reg       regWrite, 
    output reg [1:0] aluSrc,
    output reg [1:0] wdSrc,
    output reg [2:0] aluControl,
    output reg       mem_req_valid_o,
    output reg       mem_wr_o
);
    reg          branch;
    reg          condZero;
    reg          handshake_was;
    assign pcSrc = branch & (aluZero == condZero);

    always @ (*) begin
        pc_we           = 1'b1;
        branch          = 1'b0;
        condZero        = 1'b0;
        regWrite        = 1'b0;
        aluSrc          = 2'b00;
        wdSrc           = 2'b00;
        aluControl      = `ALU_ADD;
        mem_req_valid_o = 1'b0;
        mem_wr_o        = 1'b0;

        casez( {cmdF7, cmdF3, cmdOp} )
            { `RVF7_ADD,  `RVF3_ADD,  `RVOP_ADD  } : begin regWrite = 1'b1; aluControl = `ALU_ADD;  end
            { `RVF7_OR,   `RVF3_OR,   `RVOP_OR   } : begin regWrite = 1'b1; aluControl = `ALU_OR;   end
            { `RVF7_SRL,  `RVF3_SRL,  `RVOP_SRL  } : begin regWrite = 1'b1; aluControl = `ALU_SRL;  end
            { `RVF7_SLTU, `RVF3_SLTU, `RVOP_SLTU } : begin regWrite = 1'b1; aluControl = `ALU_SLTU; end
            { `RVF7_SUB,  `RVF3_SUB,  `RVOP_SUB  } : begin regWrite = 1'b1; aluControl = `ALU_SUB;  end

            { `RVF7_ANY,  `RVF3_ADDI, `RVOP_ADDI } : begin regWrite = 1'b1; aluSrc = 2'b01; aluControl = `ALU_ADD; end
            { `RVF7_ANY,  `RVF3_ANY,  `RVOP_LUI  } : begin regWrite = 1'b1; wdSrc  = 2'b01; end
            { `RVF7_ANY,  `RVF3_LW,   `RVOP_LW   } : begin regWrite = 1'b1; aluSrc = 2'b01; wdSrc = 2'b10; aluControl = `ALU_ADD; pc_we = mem_resp_valid_i; mem_req_valid_o = !handshake_was; mem_wr_o = 1'b0; end
            { `RVF7_ANY,  `RVF3_SW,   `RVOP_SW   } : begin                  aluSrc = 2'b10; aluControl = `ALU_ADD; pc_we = mem_resp_valid_i; mem_req_valid_o = !handshake_was; mem_wr_o = 1'b1; end
            { `RVF7_MUL,  `RVF3_MUL,  `RVOP_MUL  } : begin regWrite = 1'b1; aluControl = `ALU_MUL;  end

            { `RVF7_ANY,  `RVF3_BEQ,  `RVOP_BEQ  } : begin branch = 1'b1; condZero = 1'b1; aluControl = `ALU_SUB; end
            { `RVF7_ANY,  `RVF3_BNE,  `RVOP_BNE  } : begin branch = 1'b1; aluControl = `ALU_SUB; end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            handshake_was <= '0;
        end
        else begin
            if (mem_req_valid_o && mem_req_ready_i) begin
                handshake_was <= '1;
            end
            if (mem_resp_valid_i) begin
                handshake_was <= '0;
            end
        end
    end
endmodule

module sr_alu
(
    input  [31:0] srcA,
    input  [31:0] srcB,
    input  [ 2:0] oper,
    output        zero,
    output reg [31:0] result
);
    always @ (*) begin
        case (oper)
            default   : result = srcA + srcB;
            `ALU_ADD  : result = srcA + srcB;
            `ALU_OR   : result = srcA | srcB;
            `ALU_SRL  : result = srcA >> srcB [4:0];
            `ALU_SLTU : result = (srcA < srcB) ? 1 : 0;
            `ALU_SUB  : result = srcA - srcB;
            `ALU_MUL  : result = srcA * srcB;
        endcase
    end

    assign zero   = (result == 0);
endmodule

module sm_register_file
(
    input         clk,
    input         rst_n,
    input  [ 4:0] a0,
    input  [ 4:0] a1,
    input  [ 4:0] a2,
    input  [ 4:0] a3,
    output [31:0] rd0,
    output [31:0] rd1,
    output [31:0] rd2,
    input  [31:0] wd3,
    input         we3
);
    reg [31:0] rf [31:0];

    assign rd0 = (a0 != 0) ? rf [a0] : 32'b0;
    assign rd1 = (a1 != 0) ? rf [a1] : 32'b0;
    assign rd2 = (a2 != 0) ? rf [a2] : 32'b0;

    always_ff @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rf <= '{default:'0};
        end
        else begin
            if(we3) rf [a3] <= wd3;
        end
    end
endmodule