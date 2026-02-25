`ifndef __DEFINES__
`define __DEFINES__

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


/* -- AXI section -- */
`define GENERATE_AXI_TYPEDEFS \
typedef struct packed {                      \
    logic [AXI_ADDR_WIDTH-1:0]     AWADDR  ; \
    logic [7:0]                    AWLEN   ; \
    logic [2:0]                    AWSIZE  ; \
    logic [1:0]                    AWBURST ; \
    logic [AXI_ID_W_WIDTH-1:0]     AWID    ; \
} axi_data_aw_t;                             \
typedef struct packed {                      \
    logic [AXI_DATA_WIDTH-1:0]     WDATA   ; \
    logic [(AXI_DATA_WIDTH/8)-1:0] WSTRB   ; \
    logic                          WLAST   ; \
} axi_data_w_t;                              \
typedef struct packed {                      \
    logic [AXI_ADDR_WIDTH-1:0]     ARADDR  ; \
    logic [7:0]                    ARLEN   ; \
    logic [2:0]                    ARSIZE  ; \
    logic [1:0]                    ARBURST ; \
    logic [AXI_ID_R_WIDTH-1:0]     ARID    ; \
} axi_data_ar_t;                             \
typedef struct packed {                      \
    logic [AXI_ID_W_WIDTH-1:0]     BID     ; \
} axi_data_b_t                             ; \
typedef struct packed {                      \
    logic [AXI_DATA_WIDTH-1:0]     RDATA   ; \
    logic                          RLAST   ; \
    logic [AXI_ID_R_WIDTH-1:0]     RID     ; \
} axi_data_r_t                             ; \
typedef struct packed {                      \
    axi_data_aw_t                  aw      ; \
    axi_data_w_t                   w       ; \
    axi_data_ar_t                  ar      ; \
} axi_data_mosi_t                          ; \
typedef struct packed {                      \
    axi_data_b_t                   b       ; \
    axi_data_r_t                   r       ; \
} axi_data_miso_t                          ; \
typedef struct packed {                      \
    axi_data_mosi_t                data    ; \
    logic                          AWVALID ; \
    logic                          WVALID  ; \
    logic                          ARVALID ; \
    logic                          BREADY  ; \
    logic                          RREADY  ; \
} axi_mosi_t                               ; \
typedef struct packed {                      \
    axi_data_miso_t                data    ; \
    logic                          AWREADY ; \
    logic                          WREADY  ; \
    logic                          ARREADY ; \
    logic                          BVALID  ; \
    logic                          RVALID  ; \
} axi_miso_t                               ;


`define AXI_INTERFACE_SLAVE2TYPEDEF(slave, mosi_typedef, miso_typedef) \
assign mosi_typedef.AWVALID         = slave.AWVALID             ; \
assign slave.AWREADY                = miso_typedef.AWREADY      ; \
assign mosi_typedef.data.aw.AWADDR  = slave.AWADDR              ; \
assign mosi_typedef.data.aw.AWLEN   = slave.AWLEN               ; \
assign mosi_typedef.data.aw.AWSIZE  = slave.AWSIZE              ; \
assign mosi_typedef.data.aw.AWBURST = slave.AWBURST             ; \
assign mosi_typedef.data.aw.AWID    = slave.AWID                ; \
                                                                  \
assign mosi_typedef.WVALID          = slave.WVALID              ; \
assign slave.WREADY                 = miso_typedef.WREADY       ; \
assign mosi_typedef.data.w.WDATA    = slave.WDATA               ; \
assign mosi_typedef.data.w.WSTRB    = slave.WSTRB               ; \
assign mosi_typedef.data.w.WLAST    = slave.WLAST               ; \
                                                                  \
assign slave.BVALID                 = miso_typedef.BVALID       ; \
assign mosi_typedef.BREADY          = slave.BREADY              ; \
assign slave.BID                    = miso_typedef.data.b.BID   ; \
                                                                  \
assign mosi_typedef.ARVALID         = slave.ARVALID             ; \
assign slave.ARREADY                = miso_typedef.ARREADY      ; \
assign mosi_typedef.data.ar.ARADDR  = slave.ARADDR              ; \
assign mosi_typedef.data.ar.ARLEN   = slave.ARLEN               ; \
assign mosi_typedef.data.ar.ARSIZE  = slave.ARSIZE              ; \
assign mosi_typedef.data.ar.ARBURST = slave.ARBURST             ; \
assign mosi_typedef.data.ar.ARID    = slave.ARID                ; \
                                                                  \
assign slave.RVALID                 = miso_typedef.RVALID       ; \
assign mosi_typedef.RREADY          = slave.RREADY              ; \
assign slave.RDATA                  = miso_typedef.data.r.RDATA ; \
assign slave.RLAST                  = miso_typedef.data.r.RLAST ; \
assign slave.RID                    = miso_typedef.data.r.RID   ;


`define AXI_INTERFACE_MASTER2TYPEDEF(master, mosi_typedef, miso_typedef) \
assign master.AWVALID            = mosi_typedef.AWVALID         ; \
assign miso_typedef.AWREADY      = master.AWREADY               ; \
assign master.AWADDR             = mosi_typedef.data.aw.AWADDR  ; \
assign master.AWLEN              = mosi_typedef.data.aw.AWLEN   ; \
assign master.AWSIZE             = mosi_typedef.data.aw.AWSIZE  ; \
assign master.AWBURST            = mosi_typedef.data.aw.AWBURST ; \
assign master.AWID               = mosi_typedef.data.aw.AWID    ; \
                                                                  \
assign master.WVALID             = mosi_typedef.WVALID          ; \
assign miso_typedef.WREADY       = master.WREADY                ; \
assign master.WDATA              = mosi_typedef.data.w.WDATA    ; \
assign master.WSTRB              = mosi_typedef.data.w.WSTRB    ; \
assign master.WLAST              = mosi_typedef.data.w.WLAST    ; \
                                                                  \
assign miso_typedef.BVALID       = master.BVALID                ; \
assign master.BREADY             = mosi_typedef.BREADY          ; \
assign miso_typedef.data.b.BID   = master.BID                   ; \
                                                                  \
assign master.ARVALID            = mosi_typedef.ARVALID         ; \
assign miso_typedef.ARREADY      = master.ARREADY               ; \
assign master.ARADDR             = mosi_typedef.data.ar.ARADDR  ; \
assign master.ARLEN              = mosi_typedef.data.ar.ARLEN   ; \
assign master.ARSIZE             = mosi_typedef.data.ar.ARSIZE  ; \
assign master.ARBURST            = mosi_typedef.data.ar.ARBURST ; \
assign master.ARID               = mosi_typedef.data.ar.ARID    ; \
                                                                  \
assign miso_typedef.RVALID       = master.RVALID                ; \
assign master.RREADY             = mosi_typedef.RREADY          ; \
assign miso_typedef.data.r.RDATA = master.RDATA                 ; \
assign miso_typedef.data.r.RLAST = master.RLAST                 ; \
assign miso_typedef.data.r.RID   = master.RID                   ;


`define AXI_INTERFACE_MONITOR2TYPEDEF(monitor, mosi_typedef, miso_typedef) \
assign mosi_typedef.AWVALID         = monitor.AWVALID ; \
assign miso_typedef.AWREADY         = monitor.AWREADY ; \
assign mosi_typedef.data.aw.AWADDR  = monitor.AWADDR  ; \
assign mosi_typedef.data.aw.AWLEN   = monitor.AWLEN   ; \
assign mosi_typedef.data.aw.AWSIZE  = monitor.AWSIZE  ; \
assign mosi_typedef.data.aw.AWBURST = monitor.AWBURST ; \
assign mosi_typedef.data.aw.AWID    = monitor.AWID    ; \
                                                        \
assign mosi_typedef.WVALID          = monitor.WVALID  ; \
assign miso_typedef.WREADY          = monitor.WREADY  ; \
assign mosi_typedef.data.w.WDATA    = monitor.WDATA   ; \
assign mosi_typedef.data.w.WSTRB    = monitor.WSTRB   ; \
assign mosi_typedef.data.w.WLAST    = monitor.WLAST   ; \
                                                        \
assign miso_typedef.BVALID          = monitor.BVALID  ; \
assign mosi_typedef.BREADY          = monitor.BREADY  ; \
assign miso_typedef.data.b.BID      = monitor.BID     ; \
                                                        \
assign mosi_typedef.ARVALID         = monitor.ARVALID ; \
assign miso_typedef.ARREADY         = monitor.ARREADY ; \
assign mosi_typedef.data.ar.ARADDR  = monitor.ARADDR  ; \
assign mosi_typedef.data.ar.ARLEN   = monitor.ARLEN   ; \
assign mosi_typedef.data.ar.ARSIZE  = monitor.ARSIZE  ; \
assign mosi_typedef.data.ar.ARBURST = monitor.ARBURST ; \
assign mosi_typedef.data.ar.ARID    = monitor.ARID    ; \
                                                        \
assign miso_typedef.RVALID          = monitor.RVALID  ; \
assign mosi_typedef.RREADY          = monitor.RREADY  ; \
assign miso_typedef.data.r.RDATA    = monitor.RDATA   ; \
assign miso_typedef.data.r.RLAST    = monitor.RLAST   ; \
assign miso_typedef.data.r.RID      = monitor.RID     ;


`define AXI_INTERFACE2INTERFACE(master, slave) \
assign  slave.AWVALID = master.AWVALID ; \
assign master.AWREADY =  slave.AWREADY ; \
assign  slave.AWADDR  = master.AWADDR  ; \
assign  slave.AWLEN   = master.AWLEN   ; \
assign  slave.AWSIZE  = master.AWSIZE  ; \
assign  slave.AWBURST = master.AWBURST ; \
assign  slave.AWID    = master.AWID    ; \
                                         \
assign  slave.WVALID  = master.WVALID  ; \
assign master.WREADY  =  slave.WREADY  ; \
assign  slave.WDATA   = master.WDATA   ; \
assign  slave.WSTRB   = master.WSTRB   ; \
assign  slave.WLAST   = master.WLAST   ; \
                                         \
assign master.BVALID  =  slave.BVALID  ; \
assign  slave.BREADY  = master.BREADY  ; \
assign master.BID     =  slave.BID     ; \
                                         \
assign  slave.ARVALID = master.ARVALID ; \
assign master.ARREADY =  slave.ARREADY ; \
assign  slave.ARADDR  = master.ARADDR  ; \
assign  slave.ARLEN   = master.ARLEN   ; \
assign  slave.ARSIZE  = master.ARSIZE  ; \
assign  slave.ARBURST = master.ARBURST ; \
assign  slave.ARID    = master.ARID    ; \
                                         \
assign master.RVALID  =  slave.RVALID  ; \
assign  slave.RREADY  = master.RREADY  ; \
assign master.RDATA   =  slave.RDATA   ; \
assign master.RLAST   =  slave.RLAST   ; \
assign master.RID     =  slave.RID     ;


`endif
