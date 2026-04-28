module transmitter #(
    parameter CLK_FREQ     = 1_000_000_000,
    parameter BAUD_RATE    = 100_000_000,

    parameter CLK_PER_BAUD = CLK_FREQ / BAUD_RATE
) (
    input  logic       clk_i,
    input  logic       arstn_i,
    output logic       tx_o,

    input  logic [7:0] data_i,
    output logic       data_ready_o,
    input  logic       data_valid_i
);

    typedef enum logic [2:0] {
        IDLE,
        START,
        DATA,
        STOP
    } states_t;

    states_t state, state_next;
    logic [31:0] clk_counter, clk_counter_next;
    logic [2:0] byte_counter, byte_counter_next;
    logic [7:0] data_reg, data_reg_next;

    assign data_ready_o = (state == IDLE);

    always_ff @(posedge clk_i or negedge arstn_i) begin
        if (!arstn_i) begin
            state <= IDLE;
            clk_counter <= '0;
            byte_counter <= '0;
            data_reg <= '0;
        end
        else begin
            state <= state_next;
            clk_counter <= clk_counter_next;
            byte_counter <= byte_counter_next;
            data_reg <= data_reg_next;
        end
    end

    always_comb begin
        state_next = IDLE;

        case (state)
            IDLE: begin
                if (data_valid_i) begin
                    state_next = START;
                end
                else begin
                    state_next = IDLE;
                end
            end
            START: begin
                if (clk_counter == (CLK_PER_BAUD - 1)) begin
                    state_next = DATA;
                end
                else begin
                    state_next = START;
                end
            end
            DATA: begin
                if ((clk_counter == (CLK_PER_BAUD - 1)) && (byte_counter == 7)) begin
                    state_next = STOP;
                end
                else begin
                    state_next = DATA;
                end
            end
            STOP: begin
                if (clk_counter == (CLK_PER_BAUD - 1)) begin
                    state_next = IDLE;
                end
                else begin
                    state_next = STOP;
                end
            end
        endcase
    end

    always_comb begin
        tx_o = '1;
        byte_counter_next = byte_counter;
        clk_counter_next = clk_counter;
        data_reg_next = data_reg;

        case (state)
            IDLE: begin
                byte_counter_next = '0;
                clk_counter_next = '0;
                tx_o = '1;
                if (data_valid_i) begin
                    data_reg_next = data_i;
                end
            end
            START: begin
                tx_o = '0;
                clk_counter_next = (clk_counter == (CLK_PER_BAUD - 1)) ? '0 : clk_counter + 1;
            end
            DATA: begin
                tx_o = data_reg[byte_counter];
                clk_counter_next = (clk_counter == (CLK_PER_BAUD - 1)) ? '0 : clk_counter + 1;
                if (clk_counter == (CLK_PER_BAUD - 1)) begin
                    byte_counter_next = byte_counter + 1;
                end
            end
            STOP: begin
                tx_o = '1;
                clk_counter_next = (clk_counter == (CLK_PER_BAUD - 1)) ? '0 : clk_counter + 1;
            end
        endcase
    end

endmodule