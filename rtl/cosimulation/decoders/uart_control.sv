module uart_control #(
    parameter CORE_COUNT       = 16,
    parameter AXI_ID_WIDTH     = 5,
    parameter BAUD_RATE        = 100_000_000,
    parameter CLK_FREQ         = 1_000_000_000,
    parameter ADDR_WIDTH       = 16,
    parameter AXI_DATA_WIDTH   = 32,

    parameter CORE_COUNT_BYTES = $clog2(CORE_COUNT) / 8 + ($clog2(CORE_COUNT) % 8 != 0),
    parameter AXI_ID_BYTES     = AXI_ID_WIDTH / 8 + (AXI_ID_WIDTH % 8 != 0),
    parameter ADDR_WIDTH_BYTES = ADDR_WIDTH / 8 + (ADDR_WIDTH % 8 != 0),
    parameter AXI_DATA_BYTES   = AXI_DATA_WIDTH / 8 + (AXI_DATA_WIDTH % 8 != 0),
    parameter WSTRB_BYTES      = AXI_DATA_BYTES / 8 + (AXI_DATA_BYTES % 8 != 0)
) (
    input  logic                      clk_i,
    input  logic                      arstn_i,
    input  logic                      rx_i,
    output logic                      tx_o,

    output logic [4:0]                pmu_addr_o   [CORE_COUNT],
    input  logic [31:0]               pmu_data_i   [CORE_COUNT],

    output logic                      resp_wait_o  [CORE_COUNT],
    output logic [AXI_ID_WIDTH-1:0]   id_o         [CORE_COUNT],
    output logic                      write_o      [CORE_COUNT],
    output logic [ADDR_WIDTH-1:0]     axaddr_o     [CORE_COUNT],
    output logic [7:0]                axlen_o      [CORE_COUNT],
    output logic [AXI_DATA_WIDTH-1:0] wdata_o      [CORE_COUNT],
    output logic [AXI_DATA_BYTES-1:0] wstrb_o      [CORE_COUNT],
    output logic                      fifo_push_o  [CORE_COUNT],
    output logic                      start_o,
    input  logic                      idle_i       [CORE_COUNT],

    input  logic [AXI_DATA_WIDTH-1:0] rdata_i,

    output logic                      rstn_o,
    output logic                      pmu_enable_o
);

    typedef enum logic [3:0] {
        IDLE,
        TEST,                   // rx_i <- 0x01;  rx_i <- any number;                         tx_o -> rx_i + 1.
        CREATE_QUICK_AXI_READ,  // rx_i <- 0x02;  rx_i <- core ID (LSB to MSB);               rx_i <- AXI_ID;     rx_i <- AXLEN;       rx_i <- resp_wait bit.
        CREATE_QUICK_AXI_WRITE, // rx_i <- 0x03;  rx_i <- core ID (LSB to MSB);               rx_i <- AXI_ID;     rx_i <- AXLEN;       rx_i <- resp_wait bit.
        READ_IDLE_STATUS,       // rx_i <- 0x04;  tx_o -> idle status bit for every AXI gen.
        AXI_START,              // rx_i <- 0x05.
        READ_PMU_DATA,          // rx_i <- 0x06;  rx_i <- core ID (LSB to MSB);               rx_i <- PMU metric; tx_o -> PMU data.
        READ_CTRL_STATUS,       // rx_i <- 0x07;  tx_o -> uart_control current state.
        RESET,                  // rx_i <- 0x08;  rx_i <- reset_value.
        PMU_ENABLE,             // rx_i <- 0x09;  rx_i <- PMU enable value.
        READ_MEMORY,            // rx_i <- 0x0A;  rx_i <- ARADDR;                             rx_i <- AXI_ID;     tx_o -> memory data.
        CREATE_AXI_READ,        // rx_i <- 0x0B;  rx_i <- core ID (LSB to MSB);               rx_i <- ARADDR;     rx_i <- AXI_ID;      rx_i <- AXLEN;    rx_i <- WDATA;         rx_i <- WSTRB; rx_i <- resp_wait bit.
        CREATE_AXI_WRITE        // rx_i <- 0x0C;  rx_i <- core ID (LSB to MSB);               rx_i <- AWADDR;     rx_i <- AXI_ID;      rx_i <- AXLEN;    rx_i <- resp_wait bit.
    } commands_t;

    commands_t state, state_next;

    logic rstn_next;

    logic [7:0]                rx_data, tx_data, tx_data_next;
    logic                      rx_data_valid, tx_data_valid, tx_data_valid_next;
    logic                      tx_data_ready;

    logic [31:0]               trans_counter, trans_counter_next;

    logic [4:0]                pmu_addr_next   [CORE_COUNT];

    logic                      resp_wait_next  [CORE_COUNT];
    logic [AXI_ID_WIDTH-1:0]   id_next         [CORE_COUNT];
    logic [ADDR_WIDTH-1:0]     axaddr_next     [CORE_COUNT];
    logic [7:0]                axlen_next      [CORE_COUNT];
    logic [AXI_DATA_WIDTH-1:0] wdata_next      [CORE_COUNT];
    logic [AXI_DATA_BYTES-1:0] wstrb_next      [CORE_COUNT];
    logic                      start_next;

    logic [$clog2(CORE_COUNT)-1:0] core_select, core_select_next;
    
    logic [CORE_COUNT-1:0] idle_packed;
    logic [CORE_COUNT-1:0] idle_reg, idle_reg_next;
    logic [31:0] pmu_data_reg, pmu_data_reg_next;
    logic pmu_to_reg, pmu_to_reg_next;
    logic pmu_enable_next;

    logic [3:0] start_delayer, start_delayer_next;

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
        .data_ready_i ('1),
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
            id_o <= '{default:'0};
            axaddr_o <= '{default:'0};
            axlen_o <= '{default:'0};
            wdata_o <= '{default:'0};
            wstrb_o <= '{default:'0};
            resp_wait_o <= '{default:'0};
            start_o <= '0;
            trans_counter <= '0;
            pmu_addr_o <= '{default:'0};
            idle_reg <= '0;
            pmu_data_reg <= '0;
            pmu_to_reg <= '0;
            rstn_o <= '0;
            pmu_enable_o <= '0;
            start_delayer <= '0;
        end
        else begin
            state <= state_next;
            tx_data <= tx_data_next;
            tx_data_valid <= tx_data_valid_next;
            core_select <= core_select_next;
            id_o <= id_next;
            axaddr_o <= axaddr_next;
            axlen_o <= axlen_next;
            wdata_o <= wdata_next;
            wstrb_o <= wstrb_next;
            resp_wait_o <= resp_wait_next;
            start_o <= start_next;
            trans_counter <= trans_counter_next;
            pmu_addr_o <= pmu_addr_next;
            idle_reg <= idle_reg_next;
            pmu_data_reg <= pmu_data_reg_next;
            pmu_to_reg <= pmu_to_reg_next;
            rstn_o <= rstn_next;
            pmu_enable_o <= pmu_enable_next;
            start_delayer <= start_delayer_next;
        end
    end

    always_comb begin
        state_next = IDLE;

        case (state)
            IDLE: begin
                if (rx_data_valid) begin
                    case (rx_data)
                        TEST:                   state_next = TEST;
                        CREATE_QUICK_AXI_READ:  state_next = CREATE_QUICK_AXI_READ;
                        CREATE_QUICK_AXI_WRITE: state_next = CREATE_QUICK_AXI_WRITE;
                        READ_IDLE_STATUS:       state_next = READ_IDLE_STATUS;
                        AXI_START:              state_next = AXI_START;
                        READ_PMU_DATA:          state_next = READ_PMU_DATA;
                        READ_CTRL_STATUS:       state_next = READ_CTRL_STATUS;
                        RESET:                  state_next = RESET;
                        PMU_ENABLE:             state_next = PMU_ENABLE;
                        READ_MEMORY:            state_next = READ_MEMORY;
                        CREATE_AXI_READ:        state_next = CREATE_AXI_READ;
                        CREATE_AXI_WRITE:       state_next = CREATE_AXI_WRITE;
                        default:                state_next = IDLE;
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
            CREATE_QUICK_AXI_WRITE, CREATE_QUICK_AXI_READ: begin
                if (fifo_push_o[core_select]) begin
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
                if (trans_counter == (CORE_COUNT_BYTES + 1 + 4) && tx_data_ready) begin
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
            RESET: begin
                if (trans_counter == 1) begin
                    state_next = IDLE;
                end
                else begin
                    state_next = state;
                end
            end
            PMU_ENABLE: begin
                if (trans_counter == 1) begin
                    state_next = IDLE;
                end
                else begin
                    state_next = state;
                end
            end
            READ_MEMORY: begin
                if (trans_counter == (ADDR_WIDTH_BYTES + AXI_ID_BYTES + AXI_DATA_BYTES + 3) && tx_data_ready) begin
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
        id_next = id_o;
        write_o = '{CORE_COUNT{1'b0}};
        axaddr_next = axaddr_o;
        axlen_next = axlen_o;
        wdata_next = wdata_o;
        wstrb_next = wstrb_o;
        resp_wait_next = resp_wait_o;
        fifo_push_o = '{CORE_COUNT{1'b0}};
        start_next = start_o;
        pmu_addr_next = pmu_addr_o;

        idle_reg_next = idle_reg;
        pmu_data_reg_next = pmu_data_reg;

        rstn_next = rstn_o;
        pmu_enable_next = pmu_enable_o;

        start_delayer_next = start_delayer;

        case (state)
            IDLE: begin
                tx_data_next = '0;
                tx_data_valid_next = '0;
                trans_counter_next = '0;

                if (rx_data_valid) begin
                    if (rx_data == READ_IDLE_STATUS) begin
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
            CREATE_QUICK_AXI_READ, CREATE_QUICK_AXI_WRITE: begin
                write_o[core_select] = (state == CREATE_QUICK_AXI_WRITE);
                fifo_push_o[core_select] = trans_counter > (CORE_COUNT_BYTES + AXI_ID_BYTES + 1);

                wdata_next[core_select] = 'h30 + core_select;
                wstrb_next[core_select] = '1;
                axaddr_next[core_select] = core_select << 5;

                if (rx_data_valid) begin
                    trans_counter_next = trans_counter + 1;
                    if (trans_counter < CORE_COUNT_BYTES) begin
                        core_select_next[trans_counter*8 +: 8] = rx_data;
                    end
                    else if (trans_counter < (CORE_COUNT_BYTES + AXI_ID_BYTES)) begin
                        id_next[core_select][(trans_counter - CORE_COUNT_BYTES)*8 +: 8] = rx_data;
                    end
                    else if (trans_counter < (CORE_COUNT_BYTES + AXI_ID_BYTES + 1)) begin
                        axlen_next[core_select] = rx_data;
                        trans_counter_next = trans_counter + 1;
                    end
                    else begin
                        resp_wait_next[core_select] = rx_data[0];
                    end
                end
            end
            CREATE_AXI_READ, CREATE_AXI_WRITE: begin
                write_o[core_select] = (state == CREATE_AXI_WRITE);

                if (state == CREATE_AXI_WRITE) begin
                    fifo_push_o[core_select] = trans_counter > (CORE_COUNT_BYTES + ADDR_WIDTH_BYTES + AXI_ID_BYTES + 1 + AXI_DATA_BYTES + WSTRB_BYTES);
                end
                else begin
                    fifo_push_o[core_select] = trans_counter > (CORE_COUNT_BYTES + ADDR_WIDTH_BYTES + AXI_ID_BYTES + 1);
                end

                if (rx_data_valid) begin
                    trans_counter_next = trans_counter + 1;
                    if (trans_counter < CORE_COUNT_BYTES) begin
                        core_select_next[trans_counter*8 +: 8] = rx_data;
                    end
                    else if (trans_counter < (CORE_COUNT_BYTES + ADDR_WIDTH_BYTES)) begin
                        axaddr_next[core_select][(trans_counter - CORE_COUNT_BYTES)*8 +: 8] = rx_data;
                    end
                    else if (trans_counter < (CORE_COUNT_BYTES + ADDR_WIDTH_BYTES + AXI_ID_BYTES)) begin
                        id_next[core_select][(trans_counter - CORE_COUNT_BYTES - ADDR_WIDTH_BYTES)*8 +: 8] = rx_data;
                    end
                    else if (trans_counter < (CORE_COUNT_BYTES + ADDR_WIDTH_BYTES + AXI_ID_BYTES + 1)) begin
                        axlen_next[core_select] = rx_data;
                    end
                    else if ((state == CREATE_AXI_WRITE) && (trans_counter < (CORE_COUNT_BYTES + ADDR_WIDTH_BYTES + AXI_ID_BYTES + 1 + AXI_DATA_BYTES))) begin
                        wdata_next[core_select][(trans_counter - CORE_COUNT_BYTES - ADDR_WIDTH_BYTES - 1 - AXI_ID_BYTES)*8 +: 8] = rx_data;
                    end
                    else if ((state == CREATE_AXI_WRITE) && (trans_counter < (CORE_COUNT_BYTES + ADDR_WIDTH_BYTES + AXI_ID_BYTES + 1 + AXI_DATA_BYTES + WSTRB_BYTES))) begin
                        wstrb_next[core_select][(trans_counter - CORE_COUNT_BYTES - ADDR_WIDTH_BYTES - 1 - AXI_ID_BYTES - AXI_DATA_BYTES)*8 +: 8] = rx_data;
                    end
                    else begin
                        resp_wait_next[core_select] = rx_data[0];
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
                        tx_data_valid_next = (trans_counter < (CORE_COUNT_BYTES + 1 + 4));

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
            RESET: begin
                if (rx_data_valid) begin
                    trans_counter_next = trans_counter + 1;
                    rstn_next = rx_data[0];
                end
            end
            PMU_ENABLE: begin
                if (rx_data_valid) begin
                    trans_counter_next = trans_counter + 1;
                    pmu_enable_next = rx_data[0];
                end
            end
            READ_MEMORY: begin
                write_o[0] = '0;
                fifo_push_o[0] = (trans_counter == (ADDR_WIDTH_BYTES + AXI_ID_BYTES));
                start_next = (trans_counter == (ADDR_WIDTH_BYTES + AXI_ID_BYTES + 1));
                axlen_next[0] = '0;

                if (rx_data_valid) begin
                    trans_counter_next = trans_counter + 1;
                    if (trans_counter < ADDR_WIDTH_BYTES) begin
                        axaddr_next[0][trans_counter*8 +: 8] = rx_data;
                    end
                    else if (trans_counter < (ADDR_WIDTH_BYTES + AXI_ID_BYTES)) begin
                        id_next[0][(trans_counter - ADDR_WIDTH_BYTES)*8 +: 8] = rx_data;
                    end
                end

                if ((trans_counter == (ADDR_WIDTH_BYTES + AXI_ID_BYTES + 1)) || (trans_counter == (ADDR_WIDTH_BYTES + AXI_ID_BYTES))) begin
                    start_delayer_next = start_delayer + 1;
                    if (start_delayer == 10) begin
                        trans_counter_next = trans_counter + 1;
                        start_delayer_next = '0;
                    end
                end

                if (!idle_i[0] && (trans_counter == (ADDR_WIDTH_BYTES + AXI_ID_BYTES + 2))) begin
                    trans_counter_next = trans_counter + 1;
                end

                if (idle_i[0] && (trans_counter > (ADDR_WIDTH_BYTES + AXI_ID_BYTES + 2))) begin
                    tx_data_next = rdata_i[(trans_counter - ADDR_WIDTH_BYTES - AXI_ID_BYTES - 3)*8 +: 8];
                    tx_data_valid_next = (trans_counter < (ADDR_WIDTH_BYTES + AXI_ID_BYTES + AXI_DATA_BYTES + 3));
                    if (tx_data_valid && tx_data_ready) begin
                        trans_counter_next = trans_counter + 1;
                    end
                end
            end
        endcase
    end

endmodule