module uart_control #(
    parameter CORE_COUNT       = 16,
    parameter AXI_ID_WIDTH     = 5,
    parameter BAUD_RATE        = 100_000_000,
    parameter CLK_FREQ         = 1_000_000_000,

    parameter CORE_COUNT_BYTES = $clog2(CORE_COUNT) / 8 + ($clog2(CORE_COUNT) % 8 != 0),
    parameter AXI_ID_BYTES     = AXI_ID_WIDTH / 8 + (AXI_ID_WIDTH % 8 != 0)
) (
    input  logic                    clk_i,
    input  logic                    arstn_i,
    input  logic                    rx_i,
    output logic                    tx_o,

    output logic [4:0]              pmu_addr_o   [CORE_COUNT],
    input  logic [63:0]             pmu_data_i   [CORE_COUNT],

    output logic [7:0]              req_depth_o,
    output logic [AXI_ID_WIDTH-1:0] id_o         [CORE_COUNT],
    output logic                    write_o      [CORE_COUNT],
    output logic [7:0]              axlen_o      [CORE_COUNT],
    output logic                    fifo_push_o  [CORE_COUNT],
    output logic                    start_o,
    input  logic                    idle_i       [CORE_COUNT]
);

    typedef enum logic [3:0] {
        IDLE,
        TEST,             // rx_i <- 0x01;  rx_i <- any number;                         tx_o -> rx_i + 1.
        SET_REQ_DEPTH,    // rx_i <- 0x02;  rx_i <- request depth;
        CREATE_AXI_READ,  // rx_i <- 0x03;  rx_i <- core ID (LSB to MSB);               rx_i <- AXI_ID_BYTES transactions; rx_i <- AXLEN; 
        CREATE_AXI_WRITE, // rx_i <- 0x04;  rx_i <- core ID (LSB to MSB);               rx_i <- AXI_ID_BYTES transactions; rx_i <- AXLEN;
        READ_IDLE_STATUS, // rx_i <- 0x05;  tx_o -> idle status bit for every AXI gen.
        AXI_START,        // rx_i <- 0x06.
        READ_PMU_DATA,    // rx_i <- 0x07;  rx_i <- core ID (LSB to MSB);               rx_i <- PMU metric;                tx_o -> PMU data.
        READ_CTRL_STATUS  // rx_i <- 0x08;  tx_o -> uart_control current state.
    } commands_t;

    commands_t state, state_next;

    logic [7:0] rx_data, tx_data, tx_data_next;
    logic       rx_data_valid, tx_data_valid, tx_data_valid_next;
    logic       rx_data_ready, tx_data_ready;

    logic [31:0] trans_counter, trans_counter_next;

    logic [4:0]  pmu_addr_next   [16];

    logic [7:0]  req_depth_next      ;
    logic [AXI_ID_WIDTH-1:0] id_next[16];
    logic [7:0]  axlen_next      [16];
    logic        start_next          ;

    logic [$clog2(CORE_COUNT)-1:0] core_select, core_select_next;
    
    logic [CORE_COUNT-1:0] idle_packed;
    logic [CORE_COUNT-1:0] idle_reg, idle_reg_next;
    logic [63:0] pmu_data_reg, pmu_data_reg_next;
    logic pmu_to_reg, pmu_to_reg_next;

    assign rx_data_ready = '1;

    generate
        genvar i;
        for (i = 0; i < CORE_COUNT; i++) begin : pack_idle
            assign idle_packed[i] = idle_i[i];
        end
    endgenerate


    receiver #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) receiver (
        .clk_i        (clk_i),
        .arstn_i      (arstn_i),
        .rx_i         (rx_i),

        .data_o       (rx_data),
        .data_ready_i (rx_data_ready),
        .data_valid_o (rx_data_valid)
    );

    transmitter #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) transmitter (
        .clk_i        (clk_i),
        .arstn_i      (arstn_i),
        .tx_o         (tx_o),

        .data_i       (tx_data),
        .data_ready_o (tx_data_ready),
        .data_valid_i (tx_data_valid)
    );


    always_ff @(posedge clk_i or negedge arstn_i) begin
        if (!arstn_i) begin
            state <= IDLE;
            tx_data <= '0;
            tx_data_valid <= '0;
            core_select <= '0;
            req_depth_o <= '0;
            id_o <= '{default:'0};
            axlen_o <= '{default:'0};
            start_o <= '0;
            trans_counter <= '0;
            pmu_addr_o <= '{default:'0};
            idle_reg <= '0;
            pmu_data_reg <= '0;
            pmu_to_reg <= '0;
        end
        else begin
            state <= state_next;
            tx_data <= tx_data_next;
            tx_data_valid <= tx_data_valid_next;
            core_select <= core_select_next;
            req_depth_o <= req_depth_next;
            id_o <= id_next;
            axlen_o <= axlen_next;
            start_o <= start_next;
            trans_counter <= trans_counter_next;
            pmu_addr_o <= pmu_addr_next;
            idle_reg <= idle_reg_next;
            pmu_data_reg <= pmu_data_reg_next;
            pmu_to_reg <= pmu_to_reg_next;
        end
    end

    always_comb begin
        state_next = IDLE;

        case (state)
            IDLE: begin
                if (rx_data_valid) begin
                    case (rx_data)
                        8'h01: state_next = TEST;
                        8'h02: state_next = SET_REQ_DEPTH;
                        8'h03: state_next = CREATE_AXI_READ;
                        8'h04: state_next = CREATE_AXI_WRITE;
                        8'h05: state_next = READ_IDLE_STATUS;
                        8'h06: state_next = AXI_START;
                        8'h07: state_next = READ_PMU_DATA;
                        8'h08: state_next = READ_CTRL_STATUS;
                        default: state_next = IDLE;
                    endcase
                end
                else begin
                    state_next = state;
                end
            end
            TEST: begin
                if (trans_counter == 2 && tx_data_ready) begin
                    state_next = IDLE; 
                end
                else begin
                    state_next = state;
                end
            end
            SET_REQ_DEPTH: begin
                if (trans_counter == 1) begin
                    state_next = IDLE;
                end
                else begin
                    state_next = state;
                end
            end
            CREATE_AXI_WRITE, CREATE_AXI_READ: begin
                if (fifo_push_o[core_select]) begin
                    state_next = IDLE; 
                end
                else begin
                    state_next = state;
                end
            end
            READ_IDLE_STATUS: begin
                if (trans_counter == (CORE_COUNT / 8) && tx_data_ready) begin
                    state_next = IDLE; 
                end
                else begin
                    state_next = state;
                end
            end
            AXI_START: begin
                if (start_o) begin
                    state_next = IDLE; 
                end else begin
                    state_next = state;
                end
            end
            READ_PMU_DATA: begin
                if (trans_counter == (CORE_COUNT_BYTES + 1 + 8) && tx_data_ready) begin
                    state_next = IDLE; 
                end
                else begin
                    state_next = state;
                end
            end
            READ_CTRL_STATUS: begin
                if (trans_counter == 1 && tx_data_ready) begin
                    state_next = IDLE;
                end
                else begin
                    state_next = state;
                end
            end
        endcase
    end
    
    always_comb begin
        pmu_to_reg_next = pmu_to_reg;

        tx_data_next = tx_data;
        tx_data_valid_next = tx_data_valid;

        trans_counter_next = trans_counter;

        core_select_next = core_select;
        req_depth_next = req_depth_o;
        id_next = id_o;
        write_o = '{CORE_COUNT{1'b0}};
        axlen_next = axlen_o;
        fifo_push_o = '{CORE_COUNT{1'b0}};
        start_next = start_o;
        pmu_addr_next = pmu_addr_o;

        idle_reg_next = idle_reg;
        pmu_data_reg_next = pmu_data_reg;

        case (state)
            IDLE: begin
                tx_data_next = '0;
                tx_data_valid_next = '0;
                trans_counter_next = '0;

                if (rx_data_valid) begin
                    if (rx_data == 8'h05) begin
                        idle_reg_next = idle_packed; 
                    end
                end
            end
            TEST: begin
                if (rx_data_valid) begin
                    trans_counter_next = trans_counter + 1;
                    tx_data_next = rx_data + 1;
                    tx_data_valid_next = 1;
                end

                if (tx_data_valid && tx_data_ready) begin
                    trans_counter_next = trans_counter + 1;
                    tx_data_valid_next = 0;
                end
            end
            SET_REQ_DEPTH: begin
                if (rx_data_valid) begin
                    trans_counter_next = trans_counter + 1;
                    req_depth_next = rx_data;
                end
            end
            CREATE_AXI_READ, CREATE_AXI_WRITE: begin
                write_o[core_select] = (state == CREATE_AXI_WRITE);
                fifo_push_o[core_select] = trans_counter > (CORE_COUNT_BYTES + AXI_ID_BYTES);

                if (rx_data_valid) begin
                    trans_counter_next = trans_counter + 1;
                    if (trans_counter < CORE_COUNT_BYTES) begin
                        core_select_next[trans_counter*8 +: 8] = rx_data;
                    end
                    else if (trans_counter < (CORE_COUNT_BYTES + AXI_ID_BYTES)) begin
                        id_next[core_select][(trans_counter - CORE_COUNT_BYTES)*8 +: 8] = rx_data;
                    end
                    else if (trans_counter == (CORE_COUNT_BYTES + AXI_ID_BYTES)) begin
                        axlen_next[core_select] = rx_data;
                        trans_counter_next = trans_counter + 1;
                    end
                end
            end
            READ_IDLE_STATUS: begin
                tx_data_next = idle_reg[trans_counter*8 +: 8];
                tx_data_valid_next = (trans_counter < (CORE_COUNT / 8));

                if (tx_data_valid && tx_data_ready) begin
                    trans_counter_next = trans_counter + 1;
                end
            end
            AXI_START: begin
                if (!start_o) begin
                    start_next = 1;
                end
                else begin
                    start_next = 0;
                end
            end
            READ_PMU_DATA: begin
                if (trans_counter < CORE_COUNT_BYTES) begin
                    if (rx_data_valid) begin
                        trans_counter_next = trans_counter + 1;
                        core_select_next[trans_counter*8 +: 8] = rx_data;
                    end
                end
                else if (trans_counter < (CORE_COUNT_BYTES + 1)) begin
                    if (rx_data_valid) begin
                        trans_counter_next = trans_counter + 1;
                        pmu_addr_next[core_select] = rx_data[4:0];
                        pmu_to_reg_next = '1;
                    end
                end
                else begin
                    if (pmu_to_reg) begin
                        pmu_data_reg_next = pmu_data_i[core_select];
                        pmu_to_reg_next = '0;
                    end
                    else begin
                        tx_data_next = pmu_data_reg_next[(trans_counter - CORE_COUNT_BYTES - 1)*8 +: 8];
                        tx_data_valid_next = (trans_counter < (CORE_COUNT_BYTES + 1 + 8));

                        if (tx_data_valid && tx_data_ready) begin
                            trans_counter_next = trans_counter + 1;
                    end
                    end
                end
            end
            READ_CTRL_STATUS: begin
                tx_data_next = '0 | state;
                tx_data_valid_next = (trans_counter < 1);

                if (tx_data_valid && tx_data_ready) begin
                    trans_counter_next = trans_counter + 1;
                end
            end
        endcase
    end

endmodule