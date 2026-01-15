`include "defines.svh"

module queue #(
    parameter AXIS_DATA_WIDTH = 32
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
    `endif ,
    parameter BUFFER_LENGTH = 16
) (
    input clk_i, rst_n_i,

    input  axis_mosi_t in_mosi_i,
    output axis_miso_t in_miso_o,
    output axis_mosi_t out_mosi_o,
    input  axis_miso_t out_miso_i,

    output logic empty_o,
    output logic half_full_o,
    output logic full_O
);

    `include "axis_type.svh"

    axis_data_t queue_buffers [BUFFER_LENGTH];
    axis_data_t stored_axis_r, stored_axis_w;

    logic [$clog2(BUFFER_LENGTH)-1:0] ptr_write;
    logic [$clog2(BUFFER_LENGTH)-1:0] ptr_read;

    logic [$clog2(BUFFER_LENGTH)-1:0] count;

    localparam HALF_WAY_POINT = BUFFER_LENGTH/2;

    logic yes_data;

    logic [$clog2(BUFFER_LENGTH):0] distance;

    always_comb begin
        stored_axis_r = queue_buffers[ptr_read];

        stored_axis_w = in_mosi_i.data;

    end

    always_ff @(posedge clk_i) begin
        out_mosi_o.data <= stored_axis_r;
        out_mosi_o.TVALID <= yes_data;
    end

    always_ff @(posedge clk_i or negedge rst_n_i)
    begin
        if(!rst_n_i) begin
            ptr_write <= '0;
            ptr_read <= '0;
            in_miso_o.TREADY <= 1'b1;
            count <= '0;
        end else begin
            if(in_mosi_i.TVALID && in_miso_o.TREADY) begin
                queue_buffers[ptr_write] <= stored_axis_w;
                ptr_write = (ptr_write + 1'b1) % BUFFER_LENGTH;
                count = count + 1'b1;
            end
            if(out_miso_i.TREADY && count) begin
                ptr_read = (ptr_read + 1'b1) % BUFFER_LENGTH;
                in_miso_o.TREADY <= 1'b1;
                count = count - 1'b1;
            end
            if(in_mosi_i.TVALID && in_miso_o.TREADY) begin
                if(ptr_write == ptr_read) begin
                    in_miso_o.TREADY <= 1'b0;
                end
            end
        end
    end

    always_comb begin
        empty = count == 0;
        half_full = count > HALF_WAY_POINT;
        full = count == BUFFER_LENGTH;
    end

endmodule
