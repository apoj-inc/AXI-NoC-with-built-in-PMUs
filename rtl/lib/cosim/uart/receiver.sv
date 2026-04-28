module receiver #(
    parameter CLK_FREQ          = 1_000_000_000,
    parameter BAUD_RATE         = 100_000_000,

    parameter CLK_PER_BAUD      = CLK_FREQ / BAUD_RATE,
    parameter CLK_UART_MIDPOINT = CLK_PER_BAUD / 2
) (
    input  logic       clk_i,
    input  logic       arstn_i,
    input  logic       rx_i,

    output logic [7:0] data_o,
    input  logic       data_ready_i,
    output logic       data_valid_o
);

    typedef enum logic [2:0] {
        IDLE,
        START,
        DATA,
        STOP
    } states_t;

    states_t state, state_next;
    logic data_valid, data_valid_next;
    logic [31:0] clk_counter, clk_counter_next;
    logic [2:0] byte_counter, byte_counter_next;
    logic [7:0] data, data_next;

    assign data_valid_o = data_valid;
    assign data_o = data;


    always_ff @(posedge clk_i or negedge arstn_i) begin
        if (!arstn_i) begin
            state <= IDLE;
            data_valid <= '0;
            data <= '0;
            clk_counter <= '0;
            byte_counter <= '0;
        end
        else begin
            state <= state_next;
            data_valid <= data_valid_next;
            data <= data_next;
            clk_counter <= clk_counter_next;
            byte_counter <= byte_counter_next;
        end
    end

    always_comb begin
        state_next = IDLE;

        case (state)
            IDLE: begin
                if (!rx_i) begin
                    state_next = START;
                end
                else begin
                    state_next = IDLE;
                end
            end
            START: begin
                if (clk_counter == CLK_UART_MIDPOINT) begin
                    if (!rx_i) begin
                        state_next = DATA;
                    end
                    else begin
                        state_next = START;
                    end
                end
                if (clk_counter == (CLK_PER_BAUD - 1)) begin
                    state_next = DATA;
                end
                else begin
                    state_next = START;
                end
            end
            DATA: begin
                if ((clk_counter == CLK_UART_MIDPOINT) && (byte_counter == 7)) begin
                    state_next = STOP;
                end
                else begin
                    state_next = DATA;
                end
            end
            STOP: begin
                if (clk_counter == CLK_UART_MIDPOINT) begin
                    state_next = IDLE;
                end
                else begin
                    state_next = STOP;
                end
            end
        endcase
    end

    always_comb begin
        data_valid_next = data_valid;
        clk_counter_next = clk_counter;
        byte_counter_next = byte_counter;
        data_next = data;

        case (state)
            IDLE: begin
                clk_counter_next = '0;
                byte_counter_next = '0;
                if (!rx_i) begin
                    clk_counter_next = 1;
                end

                if (data_valid_o && data_ready_i) begin
                    data_valid_next = '0;
                end
            end
            START: begin
                data_valid_next = '0;
                data_next = '0;
                clk_counter_next = (clk_counter == (CLK_PER_BAUD - 1)) ? '0 : clk_counter + 1;
            end
            DATA: begin
                clk_counter_next = (clk_counter == (CLK_PER_BAUD - 1)) ? '0 : clk_counter + 1;

                if (clk_counter == CLK_UART_MIDPOINT) begin
                    data_next[byte_counter] = rx_i;
                end
                if (clk_counter == (CLK_PER_BAUD - 1)) begin
                    byte_counter_next = byte_counter + 1;
                end
            end
            STOP: begin
                clk_counter_next = (clk_counter == (CLK_PER_BAUD - 1)) ? '0 : clk_counter + 1;

                if (clk_counter == CLK_UART_MIDPOINT) begin
                    if (rx_i) begin
                        data_valid_next = '1;
                    end
                    else begin
                        data_valid_next = '0;
                    end
                end
                
                if (data_valid_o && data_ready_i) begin
                    data_valid_next = '0;
                end
            end
        endcase
    end
    
endmodule