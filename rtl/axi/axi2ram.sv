module axi2ram
#(
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter BYTE_WIDTH = 8,
    parameter BATCH_WIDTH = DATA_WIDTH/BYTE_WIDTH
)
(
	input clk, rst_n,

    // Port a 
    output logic [ADDR_WIDTH-1:0] addr_a,
    output logic [DATA_WIDTH-1:0] write_a,
    output logic write_en_a,
    output logic [BATCH_WIDTH-1:0] byte_en_a,
    input  logic [DATA_WIDTH-1:0] data_a,

    // Port b 
    output logic [ADDR_WIDTH-1:0] addr_b,
    output logic [DATA_WIDTH-1:0] write_b,
    output logic write_en_b,
    output logic [BATCH_WIDTH-1:0] byte_en_b,
    input  logic [DATA_WIDTH-1:0] data_b,

    //AXI
    input axi_data_aw_t axi_data_aw,
    
    input  logic aw_valid, w_valid, ar_valid,
    output logic aw_ready, w_ready, ar_ready,

    output axi_data_aw_t axi_data_br,

    output logic b_valid, r_valid,
    input  logic b_ready, r_ready

);
    localparam WSRTB_W = DATA_WIDTH/BYTE_WIDTH;

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

    always_ff @( posedge clk or negedge rst_n ) begin : StateSwitchBlock
        if(!rst_n) begin            
            r_state <= READING_ADDRESS;
            w_state <= READING_ADDRESS;
        end else begin
            r_state <= r_state_next;
            w_state <= w_state_next;
        end
    end : StateSwitchBlock

    always_comb begin : FSMOutputBlock
        r_state_next = READING_ADDRESS;

        ar_ready = 1'b0;
        r_valid = 1'b0;
        axi_data_br.RLAST = 1'b0;
        axi_data_br.RID = ARID;

        addr_a = r_state == RESPONDING ? (ARBURST == 2'b01) ? ARADDR + r_ready : 
                    (ARBURST == 2'b10) ? (ARADDR + r_ready > 2**ADDR_WIDTH-1 ? '0 : ARADDR + r_ready) : ARADDR
                    : ARADDR;
        byte_en_a = '0;
        write_a = '0;
        axi_data_br.RDATA = data_a;

                
        case (r_state)
            READING_ADDRESS: begin
                r_state_next = READING_ADDRESS;
                ar_ready = 1'b1;
                if(ar_valid)
                    r_state_next = REQUESTING_DATA;
            end
            REQUESTING_DATA:
                r_state_next = RESPONDING;
            RESPONDING: begin
                r_state_next = RESPONDING;
                r_valid = 1'b1;
                if(ARLEN == 8'o0) begin
                    axi_data_br.RLAST = 1'b1;
                    if(r_ready)
                        r_state_next = READING_ADDRESS;
                end
            end
            default:;
        endcase
        
        w_state_next = READING_ADDRESS;

        aw_ready = 1'b0;
        w_ready = 1'b0;
        axi_data_br.BID = AWID;
        b_valid = 1'b0;

        byte_en_b = 1'b0;
        addr_b = AWADDR;
        write_b = axi_data_aw.WDATA;

        case (w_state)
            READING_ADDRESS: begin
                w_state_next = READING_ADDRESS;
                aw_ready = 1'b1;
                if(aw_valid)
                    w_state_next = REQUESTING_DATA;
            end
            REQUESTING_DATA: begin

                w_ready = 1'b1;
                w_state_next = REQUESTING_DATA;

                byte_en_b = axi_data_aw.WSTRB;

                if(w_valid) begin
                    if(AWLEN == 1'b0 || axi_data_aw.WLAST) begin
                        w_state_next = RESPONDING;
                    end
                end
            end
            RESPONDING: begin
                w_state_next = RESPONDING;
                b_valid = 1'b1;
                if(b_ready)
                    w_state_next = READING_ADDRESS;
            end
            default:;
        endcase

    end : FSMOutputBlock

    always_ff @( posedge clk or negedge rst_n ) begin : LogicBlock
    if(!rst_n) begin
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
                ARID <= axi_data_aw.ARID;
                ARADDR <= axi_data_aw.ARADDR;
                ARLEN <= axi_data_aw.ARLEN;
                ARSIZE <= 1'b1 << axi_data_aw.ARSIZE;
                ARBURST <= axi_data_aw.ARBURST;
            end
            REQUESTING_DATA: begin
            end
            RESPONDING: begin
                if(r_ready) begin
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
                AWID <= axi_data_aw.AWID;
                AWADDR <= axi_data_aw.AWADDR;
                AWLEN <= axi_data_aw.AWLEN;
                AWSIZE <= 1'b1 << axi_data_aw.AWSIZE;
                AWBURST <= axi_data_aw.AWBURST;
            end
            REQUESTING_DATA: begin
                if(w_valid) begin
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