`ifndef __AXIS_DEFINES__
`define __AXIS_DEFINES__

/* -- AXIS section -- */
`define GENERATE_AXIS_TYPEDEFS \
typedef struct packed {                      \
    logic [AXIS_DATA_WIDTH-1:0]     TDATA  ; \
    logic [(AXIS_DATA_WIDTH/8)-1:0] TSTRB  ; \
    logic [(AXIS_DATA_WIDTH/8)-1:0] TKEEP  ; \
    logic                           TLAST  ; \
    logic [AXIS_ID_WIDTH-1:0]       TID    ; \
    logic [AXIS_DEST_WIDTH-1:0]     TDEST  ; \
    logic [AXIS_USER_WIDTH-1:0]     TUSER  ; \
} axis_data_t                              ; \
typedef struct packed {                      \
    axis_data_t                     data   ; \
    logic                           TVALID ; \
} axis_mosi_t                              ; \
typedef struct packed {                      \
    logic                           TREADY ; \
} axis_miso_t                              ;

`define AXIS_INTERFACE_SLAVE2TYPEDEF(slave, mosi_typedef, miso_typedef) \
assign mosi_typedef.TVALID     = slave.TVALID        ; \
assign slave.TREADY            = miso_typedef.TREADY ; \
assign mosi_typedef.data.TDATA = slave.TDATA         ; \
assign mosi_typedef.data.TSTRB = slave.TSTRB         ; \
assign mosi_typedef.data.TKEEP = slave.TKEEP         ; \
assign mosi_typedef.data.TLAST = slave.TLAST         ; \
assign mosi_typedef.data.TID   = slave.TID           ; \
assign mosi_typedef.data.TDEST = slave.TDEST         ; \
assign mosi_typedef.data.TUSER = slave.TUSER         ;

`define AXIS_INTERFACE_MASTER2TYPEDEF(master, mosi_typedef, miso_typedef) \
assign master.TVALID       = mosi_typedef.TVALID     ; \
assign miso_typedef.TREADY = master.TREADY           ; \
assign master.TDATA        = mosi_typedef.data.TDATA ; \
assign master.TSTRB        = mosi_typedef.data.TSTRB ; \
assign master.TKEEP        = mosi_typedef.data.TKEEP ; \
assign master.TLAST        = mosi_typedef.data.TLAST ; \
assign master.TID          = mosi_typedef.data.TID   ; \
assign master.TDEST        = mosi_typedef.data.TDEST ; \
assign master.TUSER        = mosi_typedef.data.TUSER ;

`define AXIS_INTERFACE_MONITOR2TYPEDEF(monitor, mosi_typedef, miso_typedef) \
assign mosi_typedef.TVALID     = monitor.TVALID ; \
assign miso_typedef.TREADY     = monitor.TREADY ; \
assign mosi_typedef.data.TDATA = monitor.TDATA  ; \
assign mosi_typedef.data.TSTRB = monitor.TSTRB  ; \
assign mosi_typedef.data.TKEEP = monitor.TKEEP  ; \
assign mosi_typedef.data.TLAST = monitor.TLAST  ; \
assign mosi_typedef.data.TID   = monitor.TID    ; \
assign mosi_typedef.data.TDEST = monitor.TDEST  ; \
assign mosi_typedef.data.TUSER = monitor.TUSER  ;

`define AXIS_INTERFACE2INTERFACE(master, slave) \
assign  slave.TVALID = master.TVALID ; \
assign master.TREADY =  slave.TREADY ; \
assign  slave.TDATA  = master.TDATA  ; \
assign  slave.TSTRB  = master.TSTRB  ; \
assign  slave.TKEEP  = master.TKEEP  ; \
assign  slave.TLAST  = master.TLAST  ; \
assign  slave.TID    = master.TID    ; \
assign  slave.TDEST  = master.TDEST  ; \
assign  slave.TUSER  = master.TUSER  ;

`endif
