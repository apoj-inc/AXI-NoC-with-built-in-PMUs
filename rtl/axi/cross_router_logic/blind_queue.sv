module queue #(
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH = 4,
    parameter DEST_WIDTH = 4,
    parameter USER_WIDTH = 4,
    parameter BUFFER_LENGTH = 16
) (
    input  clk, rst_n,
    input  axi_packet_t in,
    output axi_packet_t out,
);

    `include "axi_type.svh"

    axi_data_t queue_buffers [BUFFER_LENGTH];
    axi_data_t stored_axis_r, stored_axis_w;

    logic [$clog2(BUFFER_LENGTH)-1:0] ptr_write;
    logic [$clog2(BUFFER_LENGTH)-1:0] ptr_read;

    logic yes_data;

    always_comb begin
        stored_axis_r = queue_buffers[ptr_read];
        stored_axis_w = in.data;
    end

    always_ff @(posedge clk) begin
        out.data <= stored_axis_r;
        out.TVALID <= yes_data;
    end

    always_ff @(posedge clk or negedge rst_n)
    begin
        if(!rst_n) begin
            ptr_write <= '0;
            ptr_read <= '0;
            in.TREADY <= 1'b1;
            yes_data <= 0;
        end else begin
            if(in.TVALID && in.TREADY) begin
                queue_buffers[ptr_write] <= stored_axis_w;
                ptr_write = (ptr_write + 1'b1) % BUFFER_LENGTH;
                yes_data <= 1'b1;
            end
            if(out.TREADY && yes_data) begin
                ptr_read = (ptr_read + 1'b1) % BUFFER_LENGTH;
                in.TREADY <= 1'b1;
            end
            if(in.TVALID && in.TREADY) begin
                if(ptr_write == ptr_read) begin
                    in.TREADY <= 1'b0;
                end
            end
            if(out.TREADY && yes_data) begin
                if(ptr_write == ptr_read) begin
                    yes_data <= 1'b0;
                end
            end
        end
    end

endmodule
