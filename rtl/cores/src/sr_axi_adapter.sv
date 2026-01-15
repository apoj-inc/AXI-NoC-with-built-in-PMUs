`include "defines.svh"

module sr_axi_adapter #(
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter MAX_ID_WIDTH = 4,
    parameter ADDR_WIDTH = 16,

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
    `endif
) (
    input   logic         clk,        // clock
    input   logic         rst_n,      // reset

    input   logic         mem_wr_i,
    input   logic [15:0]  mem_addr_i,
    input   logic         mem_req_valid_i,
    output  logic         mem_req_ready_o,
    input   logic         mem_resp_ready_i,
    output  logic         mem_resp_valid_o,
    input   logic [31:0]  mem_wdata_i,
    output  logic [31:0]  mem_rdata_o,

    input  axi_miso_t in_miso_i,
    output axi_mosi_t in_mosi_o
);

    `include "axi_type.svh"

    logic [1:0] w_data_count;
    logic [1:0] r_data_count;
    logic aw_handshake_was;

    assign in_mosi_o.AWVALID = mem_req_valid_i & mem_wr_i & !aw_handshake_was;
    assign in_mosi_o.data.aw.AWID    = (mem_addr_i >> 12) + 1;
    assign in_mosi_o.data.aw.AWADDR  = mem_addr_i;
    assign in_mosi_o.data.aw.AWLEN   = 'h3;
    assign in_mosi_o.data.aw.AWSIZE  = 'h0;
    assign in_mosi_o.data.aw.AWBURST = 'b01;

    assign in_mosi_o.ARVALID = mem_req_valid_i & !mem_wr_i;
    assign in_mosi_o.data.ar.ARID    = (mem_addr_i >> 12) + 1;
    assign in_mosi_o.data.ar.ARADDR  = mem_addr_i;
    assign in_mosi_o.data.ar.ARLEN   = 'h3;
    assign in_mosi_o.data.ar.ARSIZE  = 'h0;
    assign in_mosi_o.data.ar.ARBURST = 'b01;

    assign in_mosi_o.WVALID  = mem_req_valid_i & mem_wr_i;
    assign in_mosi_o.data.w.WLAST   = (w_data_count == 3);
    assign in_mosi_o.data.w.WDATA   = mem_wdata_i[w_data_count * 8 +: 8];
    assign in_mosi_o.data.w.WSTRB   = '1;

    assign in_mosi_o.RREADY  = '1;

    assign in_mosi_o.BREADY  = !(in_miso_i.RVALID && in_mosi_o.RREADY && in_miso_i.data.r.RLAST);

    assign mem_req_ready_o = mem_wr_i ? in_mosi_o.WVALID & in_miso_i.WREADY & in_mosi_o.data.w.WLAST : in_miso_i.ARREADY;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_data_count <= '0;
            aw_handshake_was <= '0;
        end
        else begin
            if (in_mosi_o.AWVALID && in_miso_i.AWREADY) begin
                aw_handshake_was <= '1;
            end
            if (in_mosi_o.WVALID & in_miso_i.WREADY & in_mosi_o.data.w.WLAST) begin
                aw_handshake_was <= '0;
            end

            if (in_mosi_o.WVALID && in_miso_i.WREADY) begin
                w_data_count <= w_data_count + 1;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_data_count <= '0;
            mem_resp_valid_o <= '0;
        end
        else begin
            if (in_miso_i.RVALID && in_mosi_o.RREADY) begin
                mem_rdata_o[r_data_count * 8 +: 8] <= in_miso_i.data.r.RDATA;
                r_data_count <= r_data_count + 1;
            end

            if ((in_miso_i.RVALID && in_mosi_o.RREADY && in_miso_i.data.r.RLAST) || (in_miso_i.BVALID && in_mosi_o.BREADY))begin
                mem_resp_valid_o <= '1;
            end
            else begin
                mem_resp_valid_o <= '0;
            end
        end
    end


endmodule