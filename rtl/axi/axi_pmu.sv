`include "defines.svh"

module axi_pmu # (
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
    input  logic aclk,
    input  logic aresetn,

    input axi_miso_t mon_axi_miso,
    input axi_mosi_t mon_axi_mosi,

    input  logic [4:0]  addr_i,
    output logic [63:0] data_o
);

    `include "axi_type.svh"

    typedef struct {
        logic [63:0] idle;
        logic [63:0] outstanding;
        logic [63:0] ar_stall;
        logic [63:0] ar_handshake;
        logic [63:0] rvalid_stall;
        logic [63:0] rready_stall;
        logic [63:0] r_handshake;
    } read_counters;

    typedef struct {
        logic [63:0] idle;
        logic [63:0] outstanding;
        logic [63:0] responding;
        logic [63:0] aw_stall;
        logic [63:0] aw_handshake;
        logic [63:0] wvalid_stall;
        logic [63:0] wready_stall;
        logic [63:0] w_handshake;
        logic [63:0] bvalid_stall;
        logic [63:0] bready_stall;
        logic [63:0] b_handshake;
    } write_counters;


    read_counters rc;
    write_counters wc;
    logic [63:0] clock_counter;

    always_comb begin
        case (addr_i)
            0:  data_o <= rc.idle;
            1:  data_o <= rc.outstanding;
            2:  data_o <= rc.ar_stall;
            3:  data_o <= rc.ar_handshake;
            4:  data_o <= rc.rvalid_stall;
            5:  data_o <= rc.rready_stall;
            6:  data_o <= rc.r_handshake;
            7:  data_o <= wc.idle;
            8:  data_o <= wc.outstanding;
            9:  data_o <= wc.responding;
            10: data_o <= wc.aw_stall;
            11: data_o <= wc.aw_handshake;
            12: data_o <= wc.wvalid_stall;
            13: data_o <= wc.wready_stall;
            14: data_o <= wc.w_handshake;
            15: data_o <= wc.bvalid_stall;
            16: data_o <= wc.bready_stall;
            17: data_o <= wc.b_handshake;
            18: data_o <= clock_counter;
            default: data_o <= '0;
        endcase
    end

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            clock_counter <= 0;
        end
        else begin
            clock_counter <= clock_counter + 1;
        end
    end

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rc <= {default:'0};
        end
        else begin
            if (!mon_axi_mosi.ARVALID && (rc.outstanding == 0)) begin
                rc.idle <= rc.idle + 1;
            end

            if (mon_axi_mosi.ARVALID && mon_axi_miso.ARREADY) begin
                if (!(mon_axi_miso.RVALID && mon_axi_mosi.RREADY && mon_axi_miso.data.r.RLAST)) begin
                    rc.outstanding <= rc.outstanding + 1;
                end
            end
            else begin
                if (mon_axi_miso.RVALID && mon_axi_mosi.RREADY && mon_axi_miso.data.r.RLAST) begin
                    rc.outstanding <= rc.outstanding - 1;
                end
            end


            // --- //
            if (mon_axi_mosi.ARVALID && !mon_axi_miso.ARREADY) begin
                rc.ar_stall <= rc.ar_stall + 1;
            end

            if (mon_axi_mosi.ARVALID && mon_axi_miso.ARREADY) begin
                rc.ar_handshake <= rc.ar_handshake + 1;
            end


            // --- //
            if ((rc.outstanding != 0) && !mon_axi_miso.RVALID) begin
                rc.rvalid_stall <= rc.rvalid_stall + 1;
            end
            
            if (mon_axi_miso.RVALID && !mon_axi_mosi.RREADY) begin
                rc.rready_stall <= rc.rready_stall + 1;
            end

            if (mon_axi_miso.RVALID && mon_axi_mosi.RREADY) begin
                rc.r_handshake <= rc.r_handshake + 1;
            end
        end
    end

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            wc <= {default:'0};
        end
        else begin
            if (!mon_axi_mosi.AWVALID && (wc.outstanding == 0)) begin
                wc.idle <= wc.idle + 1;
            end

            if (mon_axi_mosi.AWVALID && mon_axi_miso.AWREADY) begin
                if (!(mon_axi_miso.BVALID && mon_axi_mosi.BREADY)) begin
                    wc.outstanding <= wc.outstanding + 1;
                end
            end
            else begin
                if (mon_axi_miso.BVALID && mon_axi_mosi.BREADY) begin
                    wc.outstanding <= wc.outstanding - 1;
                end
            end

            if (mon_axi_miso.BVALID && mon_axi_miso.BVALID) begin
                if (!(mon_axi_mosi.WVALID && mon_axi_miso.WREADY && mon_axi_mosi.data.w.WLAST)) begin
                    wc.responding <= wc.responding - 1;
                end
            end
            else begin
                if (mon_axi_mosi.WVALID && mon_axi_miso.WREADY && mon_axi_mosi.data.w.WLAST) begin
                    wc.responding <= wc.responding + 1;
                end
            end


            // --- //
            if (mon_axi_mosi.AWVALID && !mon_axi_miso.AWREADY) begin
                wc.aw_stall <= wc.aw_stall + 1;
            end

            if (mon_axi_mosi.AWVALID && mon_axi_miso.AWREADY) begin
                wc.aw_handshake <= wc.aw_handshake + 1;
            end


            // --- //
            if ((wc.outstanding != 0) && (wc.outstanding != wc.responding) && !mon_axi_mosi.WVALID) begin
                wc.wvalid_stall <= wc.wvalid_stall + 1;
            end

            if (mon_axi_mosi.WVALID && !mon_axi_miso.WREADY) begin
                wc.wready_stall <= wc.wready_stall + 1;
            end
            
            if (mon_axi_mosi.WVALID && mon_axi_miso.WREADY) begin
                wc.w_handshake <= wc.w_handshake + 1;
            end


            // --- //
            if ((wc.responding != 0) && !mon_axi_miso.BVALID) begin
                wc.bvalid_stall <= wc.bvalid_stall + 1;
            end

            if (mon_axi_miso.BVALID && !mon_axi_mosi.BREADY) begin
                wc.bready_stall <= wc.bready_stall + 1;
            end
            
            if (mon_axi_miso.BVALID && mon_axi_mosi.BREADY) begin
                wc.b_handshake <= wc.b_handshake + 1;
            end
        end
    end
    
endmodule