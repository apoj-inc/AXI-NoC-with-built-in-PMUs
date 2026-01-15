`include "defines.svh"

module axi2ram
#(
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter ADDR_WIDTH = 4,

    parameter AXI_DATA_WIDTH = 32
    `ifdef TID_PRESENT
    ,
    parameter ID_WIDTH = 4
    `endif
    `ifdef TDEST_PRESENT
    ,
    parameter DEST_WIDTH = 4
    `endif
    `ifdef TUSER_PRESENT
    ,
    parameter USER_WIDTH = 4
    `endif,
    
    parameter BYTE_WIDTH = 8,
    parameter BATCH_WIDTH = AXI_DATA_WIDTH/BYTE_WIDTH
)
(
	input clk_i, rst_n_i,

    // Port a 
    output logic [ADDR_WIDTH-1:0] addr_a,
    output logic [AXI_DATA_WIDTH-1:0] write_a,
    output logic write_en_a,
    output logic [BATCH_WIDTH-1:0] byte_en_a,
    input  logic [AXI_DATA_WIDTH-1:0] data_a,

    // Port b 
    output logic [ADDR_WIDTH-1:0] addr_b,
    output logic [AXI_DATA_WIDTH-1:0] write_b,
    output logic write_en_b,
    output logic [BATCH_WIDTH-1:0] byte_en_b,
    input  logic [AXI_DATA_WIDTH-1:0] data_b,

    //AXI
    input  axi_mosi_t in_mosi_i,
    output axi_miso_t in_miso_o

);

    `include "axi_type.svh"

    localparam WSRTB_W = AXI_DATA_WIDTH/BYTE_WIDTH;

    enum { READING_ADDRESS, REQUESTING_DATA, RESPONDING }
    r_state, r_state_next,
    w_state,  w_state_next;

    // AR channel 
    logic [ID_W_WIDTH-1:0] ARID;
    logic [ADDR_WIDTH-1:0] ARADDR;
    logic [7:0] ARLEN;
    logic [2:0] ARSIZE;
    logic [1:0] ARBURST;

    // AW channel 
    logic [ID_W_WIDTH-1:0] AWID;
    logic [ADDR_WIDTH-1:0] AWADDR;
    logic [7:0] AWLEN;
    logic [2:0] AWSIZE;
    logic [1:0] AWBURST;

    always_ff @( posedge clk_i or negedge rst_n_i ) begin : StateSwitchBlock
        if(!rst_n_i) begin            
            r_state <= READING_ADDRESS;
            w_state <= READING_ADDRESS;
        end else begin
            r_state <= r_state_next;
            w_state <= w_state_next;
        end
    end : StateSwitchBlock

    always_comb begin : FSMOutputBlock
        r_state_next = READING_ADDRESS;

        in_miso_o.ARREADY = 1'b0;
        in_miso_o.RVALID = 1'b0;
        in_miso_o.data.r.RLAST = 1'b0;
        in_miso_o.data.r.RID = ARID;

        addr_a = r_state == RESPONDING ? (ARBURST == 2'b01) ? ARADDR + in_mosi_i.RREADY : 
                    (ARBURST == 2'b10) ? (ARADDR + in_mosi_i.RREADY > 2**ADDR_WIDTH-1 ? '0 : ARADDR + in_mosi_i.RREADY) : ARADDR
                    : ARADDR;
        byte_en_a = '0;
        write_a = '0;
        in_miso_o.data.r.RDATA = data_a;

                
        case (r_state)
            READING_ADDRESS: begin
                r_state_next = READING_ADDRESS;
                in_miso_o.ARREADY = 1'b1;
                if(in_mosi_i.ARVALID)
                    r_state_next = REQUESTING_DATA;
            end
            REQUESTING_DATA:
                r_state_next = RESPONDING;
            RESPONDING: begin
                r_state_next = RESPONDING;
                in_miso_o.RVALID = 1'b1;
                if(ARLEN == 8'o0) begin
                    in_miso_o.data.r.RLAST = 1'b1;
                    if(in_mosi_i.RREADY)
                        r_state_next = READING_ADDRESS;
                end
            end
            default:;
        endcase
        
        w_state_next = READING_ADDRESS;

        in_miso_o.AWREADY = 1'b0;
        in_miso_o.WREADY = 1'b0;
        in_miso_o.data.b.BID = AWID;
        in_miso_o.BVALID = 1'b0;

        byte_en_b = 1'b0;
        addr_b = AWADDR;
        write_b = in_mosi_i.data.w.WDATA;

        case (w_state)
            READING_ADDRESS: begin
                w_state_next = READING_ADDRESS;
                in_miso_o.AWREADY = 1'b1;
                if(in_mosi_i.AWVALID)
                    w_state_next = REQUESTING_DATA;
            end
            REQUESTING_DATA: begin

                in_miso_o.WREADY = 1'b1;
                w_state_next = REQUESTING_DATA;

                byte_en_b = in_mosi_i.data.w.WSTRB;

                if(in_mosi_i.WVALID) begin
                    if(AWLEN == 1'b0 || in_mosi_i.data.w.WLAST) begin
                        w_state_next = RESPONDING;
                    end
                end
            end
            RESPONDING: begin
                w_state_next = RESPONDING;
                in_miso_o.BVALID = 1'b1;
                if(in_mosi_i.BREADY)
                    w_state_next = READING_ADDRESS;
            end
            default:;
        endcase

    end : FSMOutputBlock

    always_ff @( posedge clk_i or negedge rst_n_i ) begin : LogicBlock
    if(!rst_n_i) begin
        ARID <= '0;
        ARADDR <= '0;
        ARLEN <= '0;
        ARSIZE <= '0;
        ARBURST <= '0;

        AWID <= '0;
        AWADDR <= '0;
        AWLEN <= '0;
        AWSIZE <= '0;
        AWBURST <= '0;

    end else begin
        case (r_state)
            READING_ADDRESS: begin
                ARID <= in_mosi_i.data.ar.ARID;
                ARADDR <= in_mosi_i.data.ar.ARADDR;
                ARLEN <= in_mosi_i.data.ar.ARLEN;
                ARSIZE <= 1'b1 << in_mosi_i.data.ar.ARSIZE;
                ARBURST <= in_mosi_i.data.ar.ARBURST;
            end
            REQUESTING_DATA: begin
            end
            RESPONDING: begin
                if(in_mosi_i.RREADY) begin
                    ARLEN <= (ARLEN == 0) ? '0 : ARLEN - 1'b1;

                    case (ARBURST)
                        2'b01: begin
                            ARADDR <= ARADDR + 1'b1;
                        end
                        2'b10: begin
                            if(ARADDR + 1'b1 > 2**ADDR_WIDTH-1) begin
                                ARADDR <= '0;
                            end
                            else begin
                                ARADDR <= ARADDR + 1'b1;
                            end
                        end
                    endcase

                end
            end
            default:;
        endcase

        case (w_state)
            READING_ADDRESS: begin
                AWID <= in_mosi_i.data.aw.AWID;
                AWADDR <= in_mosi_i.data.aw.AWADDR;
                AWLEN <= in_mosi_i.data.aw.AWLEN;
                AWSIZE <= 1'b1 << in_mosi_i.data.aw.AWSIZE;
                AWBURST <= in_mosi_i.data.aw.AWBURST;
            end
            REQUESTING_DATA: begin
                if(in_mosi_i.WVALID) begin
                    AWLEN <= (AWLEN == 0) ? '0 : AWLEN - 1'b1;
                    // Address shift logic
                    case (AWBURST)
                        2'b01: AWADDR <= AWADDR + 1'b1;
                        2'b10: begin
                            if(AWADDR + 1'b1 > 2**ADDR_WIDTH-1)
                                AWADDR <= '0;
                            else
                                AWADDR <= AWADDR + 1'b1;
                        end
                    endcase
                end
            end
            default:;
        endcase

    end
    end : LogicBlock

endmodule : axi2ram