// ============================================================================
// Copyright (c) 2017 by Terasic Technologies Inc.
// ============================================================================
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// ============================================================================
//           
//  Terasic Technologies Inc
//  9F., No.176, Sec.2, Gongdao 5th Rd, East Dist, Hsinchu City, 30070. Taiwan
//  
//  
//                     web: http://www.terasic.com/  
//                     email: support@terasic.com
//
// ============================================================================
//Date:  Tue Nov 21 13:54:58 2017
// ============================================================================
`define ENABLE_PCIE

module PCIe_Fundamental(

    //////////// CLOCK //////////
    input 		          		CLOCK_50_B3B,
    input 		          		CLOCK_50_B4A,
    input 		          		CLOCK_50_B5B,
    input 		          		CLOCK_50_B6A,
    input 		          		CLOCK_50_B7A,
    input 		          		CLOCK_50_B8A,

    //////////// Buttons //////////
    input 		          		CPU_RESET_n,
    input 		     [3:0]		KEY,

    //////////// Swtiches //////////
    input 		     [3:0]		SW,

    //////////// LED //////////
    output		     [3:0]		LED,

    //////////// HEX0 //////////
    output		     [6:0]		HEX0,
    output		          		HEX0_DP,

    //////////// HEX1 //////////
    output		     [6:0]		HEX1,
    output		          		HEX1_DP,

    //////////// FAN //////////
    output		          		FAN_CTRL,

    //////////// SDRAM //////////
    output		    [12:0]		DRAM_ADDR,
    output		     [1:0]		DRAM_BA,
    output		          		DRAM_CAS_n,
    output		          		DRAM_CKE,
    output		          		DRAM_CLK,
    output		          		DRAM_CS_n,
    inout 		    [15:0]		DRAM_DQ,
    output		          		DRAM_LDQM,
    output		          		DRAM_RAS_n,
    output		          		DRAM_UDQM,
    output		          		DRAM_WE_n,

    //////////// Uart to Usb //////////
    input 		          		UART_CTS,
    output		          		UART_RTS,
    input 		          		UART_RX,
    output		          		UART_TX,

    //////////// Arduino Interface //////////
    output		          		ADC_CONVST,
    output		          		ADC_SCK,
    output		          		ADC_SDI,
    input 		          		ADC_SDO,
    inout 		    [15:0]		ARD_IO,
    
`ifdef ENABLE_PCIE
    //////////// PCIE //////////
    inout 		          		PCIE_PERST_n,
    input 		          		PCIE_REFCLK_p,
    input 		     [3:0]		PCIE_RX_p,
    inout 		          		PCIE_SMBCLK,
    inout 		          		PCIE_SMBDAT,
    output		     [3:0]		PCIE_TX_p,
    inout 		          		PCIE_WAKE_n,
`endif /*ENABLE_PCIE*/

    //////////// SMA //////////
    input 		          		SMA_CLKIN,
    output		          		SMA_CLKOUT
);

assign FAN_CTRL = 1;
logic any_rstn_r  /* synthesis ALTERA_ATTRIBUTE = "SUPPRESS_DA_RULE_INTERNAL=R102"  */;
logic any_rstn_rr /* synthesis ALTERA_ATTRIBUTE = "SUPPRESS_DA_RULE_INTERNAL=R102"  */;

//reset Synchronizer
always @(posedge CLOCK_50_B3B or negedge PCIE_PERST_n) begin
    if (PCIE_PERST_n == 0) begin
        any_rstn_r <= 0;
        any_rstn_rr <= 0;
    end
    else begin
        any_rstn_r <= 1;
        any_rstn_rr <= any_rstn_r;
    end
end

logic coreclk;
logic corerst;

logic [31:0] csr_wdata;
logic [31:0] csr_rdata;
logic [15:0] csr_addr ;
logic        csr_we   ;

logic         bar_chipselect   ;
logic [15:0]  bar_byteenable   ;
logic [127:0] bar_readdata     ;
logic [127:0] bar_writedata    ;
logic         bar_read         ;
logic         bar_write        ;
logic         bar_readdatavalid;
logic         bar_waitrequest  ;
logic [11:0]  bar_address      ;

logic         bar_0_chipselect   ;
logic [15:0]  bar_0_byteenable   ;
logic [127:0] bar_0_readdata     ;
logic [127:0] bar_0_writedata    ;
logic         bar_0_read         ;
logic         bar_0_write        ;
logic         bar_0_readdatavalid;
logic         bar_0_waitrequest  ;
logic [11:0]  bar_0_address      ;


logic         tx_chipselect   ;
logic [15:0]  tx_byteenable   ;
logic [127:0] tx_readdata     ;
logic [127:0] tx_writedata    ;
logic         tx_read         ;
logic         tx_write        ;
logic [5:0]   tx_burstcount   ;
logic         tx_readdatavalid;
logic         tx_waitrequest  ;
logic [127:0] tx_address      ;

logic [31:0]  msix_mask   [16];
logic [31:0]  msix_data   [16];
logic [63:0]  msix_addrs  [16];
logic [127:0] pba_control [1];
logic [127:0] pba_status  [1];

avmm_dma_msix_table #(
    .BAR_DATA_WIDTH (128 ),
    .BAR_ADDR_WIDTH (12  ),
    .MSI_COUNT      (16  ) 
) u_avmm_dma_msix_table (
    .clk                  (coreclk            ),
    .rst_n                (corerst            ),

    .avmm_s_chipselect    (bar_0_chipselect   ),
    .avmm_s_byteenable    (bar_0_byteenable   ),
    .avmm_s_readdata      (bar_0_readdata     ),
    .avmm_s_writedata     (bar_0_writedata    ),
    .avmm_s_read          (bar_0_read         ),
    .avmm_s_write         (bar_0_write        ),
    .avmm_s_readdatavalid (bar_0_readdatavalid),
    .avmm_s_waitrequest   (bar_0_waitrequest  ),
    .avmm_s_address       (bar_0_address      ),

    .msix_mask_o          (msix_mask          ),
    .msix_data_o          (msix_data          ),
    .msix_addrs_o         (msix_addrs         ),
    .pba_control_i        (pba_control        ),
    .pba_status_o         (pba_status         )
);

avmm_msix_tester #(
    .TX_DATA_WIDTH  (128 ),
    .TX_ADDR_WIDTH  (64  ),
    .TX_BURST_WIDTH (6   ),

    .BAR_DATA_WIDTH (128 ),
    .BAR_ADDR_WIDTH (12  ),

    .MSI_COUNT      (16  )
) (
    .clk              (coreclk),
    .rst_n            (corerst),

    .msix_mask_i      (msix_mask  ),
    .msix_data_i      (msix_data  ),
    .msix_addrs_i     (msix_addrs ),
    .pba_control_o    (pba_control),
    .pba_status_i     (pba_status ),

    .bar_chipselect   (bar_chipselect   ),
    .bar_byteenable   (bar_byteenable   ),
    .bar_readdata     (bar_readdata     ),
    .bar_writedata    (bar_writedata    ),
    .bar_read         (bar_read         ),
    .bar_write        (bar_write        ),
    .bar_readdatavalid(bar_readdatavalid),
    .bar_waitrequest  (bar_waitrequest  ),
    .bar_address      (bar_address      ),

    .tx_chipselect    (tx_chipselect    ),
    .tx_byteenable    (tx_byteenable    ),
    .tx_readdata      (tx_readdata      ),
    .tx_writedata     (tx_writedata     ),
    .tx_read          (tx_read          ),
    .tx_write         (tx_write         ),
    .tx_burstcount    (tx_burstcount    ),
    .tx_readdatavalid (tx_readdatavalid ),
    .tx_waitrequest   (tx_waitrequest   ),
    .tx_address       (tx_address       )
);

/*
avmm_dma_csr #(
    .DMA_CHANNEL_COUNT (16                  ),

    .DMA_WQ_DEPTH      ('{16{1024}}         ),
    .DMA_RQ_DEPTH      ('{16{1024}}         ),
    .DMA_TQ_DEPTH      ('{16{16  }}         ),

    .MAX_WQ_DEPTH      (1024                ),
    .MAX_RQ_DEPTH      (1024                ),
    .MAX_TQ_DEPTH      (16                  )
) u_avmm_dma_csr (
    .clk                (coreclk),
    .rst_n              (corerst),

    .csr_wdata_i        (csr_wdata),
    .csr_rdata_o        (csr_rdata),
    .csr_addr_i         (csr_addr ),
    .csr_we_i           (csr_we   ),

    .dma_addr_o         (),

    .wdata_fifo_count_i ('{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}),
    .rdata_fifo_free_i  ('{16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1}),
    .task_fifo_count_i  ('{17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32})
);
*/

my_pcie my_pcie (
    .bar_exporter_0_avmm_m_address                            (bar_0_address),      
    .bar_exporter_0_avmm_m_burstcount                         (),   
    .bar_exporter_0_avmm_m_byteenable                         (bar_0_byteenable),   
    .bar_exporter_0_avmm_m_chipselect                         (bar_0_chipselect),   
    .bar_exporter_0_avmm_m_read                               (bar_0_read),         
    .bar_exporter_0_avmm_m_readdata                           (bar_0_readdata),     
    .bar_exporter_0_avmm_m_readdatavalid                      (bar_0_readdatavalid),
    .bar_exporter_0_avmm_m_waitrequest                        (bar_0_waitrequest),  
    .bar_exporter_0_avmm_m_write                              (bar_0_write),        
    .bar_exporter_0_avmm_m_writedata                          (bar_0_writedata),

    .bar_exporter_avmm_m_address                              (bar_address),      
    .bar_exporter_avmm_m_burstcount                           (),   
    .bar_exporter_avmm_m_byteenable                           (bar_byteenable),   
    .bar_exporter_avmm_m_chipselect                           (bar_chipselect),   
    .bar_exporter_avmm_m_read                                 (bar_read),         
    .bar_exporter_avmm_m_readdata                             (bar_readdata),     
    .bar_exporter_avmm_m_readdatavalid                        (bar_readdatavalid),
    .bar_exporter_avmm_m_waitrequest                          (bar_waitrequest),  
    .bar_exporter_avmm_m_write                                (bar_write),        
    .bar_exporter_avmm_m_writedata                            (bar_writedata),
    .core_clk_clk                                             (coreclk),
    .core_reset_reset_n                                       (corerst),
	.pcie_cv_hip_avmm_0_hip_ctrl_test_in                      (32'b00000000000000000000000010001100),
	.pcie_cv_hip_avmm_0_hip_ctrl_simu_mode_pipe               (1'b0),
	.pcie_cv_hip_avmm_0_hip_pipe_sim_pipe_pclk_in             (1'b0),
	.pcie_cv_hip_avmm_0_hip_pipe_sim_pipe_rate                (),
	.pcie_cv_hip_avmm_0_hip_pipe_sim_ltssmstate               (),
	.pcie_cv_hip_avmm_0_hip_pipe_eidleinfersel0               (),
	.pcie_cv_hip_avmm_0_hip_pipe_eidleinfersel1               (),
	.pcie_cv_hip_avmm_0_hip_pipe_eidleinfersel2               (),
	.pcie_cv_hip_avmm_0_hip_pipe_eidleinfersel3               (),
	.pcie_cv_hip_avmm_0_hip_pipe_powerdown0                   (),
	.pcie_cv_hip_avmm_0_hip_pipe_powerdown1                   (),
	.pcie_cv_hip_avmm_0_hip_pipe_powerdown2                   (),
	.pcie_cv_hip_avmm_0_hip_pipe_powerdown3                   (),
	.pcie_cv_hip_avmm_0_hip_pipe_rxpolarity0                  (),
	.pcie_cv_hip_avmm_0_hip_pipe_rxpolarity1                  (),
	.pcie_cv_hip_avmm_0_hip_pipe_rxpolarity2                  (),
	.pcie_cv_hip_avmm_0_hip_pipe_rxpolarity3                  (),
	.pcie_cv_hip_avmm_0_hip_pipe_txcompl0                     (),
	.pcie_cv_hip_avmm_0_hip_pipe_txcompl1                     (),
	.pcie_cv_hip_avmm_0_hip_pipe_txcompl2                     (),
	.pcie_cv_hip_avmm_0_hip_pipe_txcompl3                     (),
	.pcie_cv_hip_avmm_0_hip_pipe_txdata0                      (),
	.pcie_cv_hip_avmm_0_hip_pipe_txdata1                      (),
	.pcie_cv_hip_avmm_0_hip_pipe_txdata2                      (),
	.pcie_cv_hip_avmm_0_hip_pipe_txdata3                      (),
	.pcie_cv_hip_avmm_0_hip_pipe_txdatak0                     (),
	.pcie_cv_hip_avmm_0_hip_pipe_txdatak1                     (),
	.pcie_cv_hip_avmm_0_hip_pipe_txdatak2                     (),
	.pcie_cv_hip_avmm_0_hip_pipe_txdatak3                     (),
	.pcie_cv_hip_avmm_0_hip_pipe_txdetectrx0                  (),
	.pcie_cv_hip_avmm_0_hip_pipe_txdetectrx1                  (),
	.pcie_cv_hip_avmm_0_hip_pipe_txdetectrx2                  (),
	.pcie_cv_hip_avmm_0_hip_pipe_txdetectrx3                  (),
	.pcie_cv_hip_avmm_0_hip_pipe_txelecidle0                  (),
	.pcie_cv_hip_avmm_0_hip_pipe_txelecidle1                  (),
	.pcie_cv_hip_avmm_0_hip_pipe_txelecidle2                  (),
	.pcie_cv_hip_avmm_0_hip_pipe_txelecidle3                  (),
	.pcie_cv_hip_avmm_0_hip_pipe_txswing0                     (),
	.pcie_cv_hip_avmm_0_hip_pipe_txswing1                     (),
	.pcie_cv_hip_avmm_0_hip_pipe_txswing2                     (),
	.pcie_cv_hip_avmm_0_hip_pipe_txswing3                     (),
	.pcie_cv_hip_avmm_0_hip_pipe_txmargin0                    (),
	.pcie_cv_hip_avmm_0_hip_pipe_txmargin1                    (),
	.pcie_cv_hip_avmm_0_hip_pipe_txmargin2                    (),
	.pcie_cv_hip_avmm_0_hip_pipe_txmargin3                    (),
	.pcie_cv_hip_avmm_0_hip_pipe_txdeemph0                    (),
	.pcie_cv_hip_avmm_0_hip_pipe_txdeemph1                    (),
	.pcie_cv_hip_avmm_0_hip_pipe_txdeemph2                    (),
	.pcie_cv_hip_avmm_0_hip_pipe_txdeemph3                    (),
	.pcie_cv_hip_avmm_0_hip_pipe_phystatus0                   (0),
	.pcie_cv_hip_avmm_0_hip_pipe_phystatus1                   (0),
	.pcie_cv_hip_avmm_0_hip_pipe_phystatus2                   (0),
	.pcie_cv_hip_avmm_0_hip_pipe_phystatus3                   (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxdata0                      (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxdata1                      (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxdata2                      (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxdata3                      (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxdatak0                     (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxdatak1                     (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxdatak2                     (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxdatak3                     (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxelecidle0                  (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxelecidle1                  (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxelecidle2                  (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxelecidle3                  (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxstatus0                    (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxstatus1                    (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxstatus2                    (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxstatus3                    (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxvalid0                     (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxvalid1                     (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxvalid2                     (0),
	.pcie_cv_hip_avmm_0_hip_pipe_rxvalid3                     (0),
	.pcie_cv_hip_avmm_0_hip_serial_rx_in0                     (PCIE_RX_p[0]),
	.pcie_cv_hip_avmm_0_hip_serial_rx_in1                     (PCIE_RX_p[1]),
	.pcie_cv_hip_avmm_0_hip_serial_rx_in2                     (PCIE_RX_p[2]),
	.pcie_cv_hip_avmm_0_hip_serial_rx_in3                     (PCIE_RX_p[3]),
	.pcie_cv_hip_avmm_0_hip_serial_tx_out0                    (PCIE_TX_p[0]),
	.pcie_cv_hip_avmm_0_hip_serial_tx_out1                    (PCIE_TX_p[1]),
	.pcie_cv_hip_avmm_0_hip_serial_tx_out2                    (PCIE_TX_p[2]),
	.pcie_cv_hip_avmm_0_hip_serial_tx_out3                    (PCIE_TX_p[3]),
	.pcie_cv_hip_avmm_0_intx_interface_intx_req			      ('0),
	.pcie_cv_hip_avmm_0_npor_npor                             (any_rstn_rr),
	.pcie_cv_hip_avmm_0_npor_pin_perst                        (PCIE_PERST_n),
	.pcie_cv_hip_avmm_0_reconfig_busy_reconfig_busy           (0),
	.pcie_cv_hip_avmm_0_reconfig_clk_locked_fixedclk_locked   (),
	.pcie_cv_hip_avmm_0_reconfig_from_xcvr_reconfig_from_xcvr (),
	.pcie_cv_hip_avmm_0_reconfig_to_xcvr_reconfig_to_xcvr     (0),
	.pcie_cv_hip_avmm_0_refclk_clk          				  (PCIE_REFCLK_p),
    .tx_exporter_avmm_s_chipselect                            (tx_chipselect   ),   
    .tx_exporter_avmm_s_byteenable                            (tx_byteenable   ),       
    .tx_exporter_avmm_s_readdata                              (tx_readdata     ),        
    .tx_exporter_avmm_s_writedata                             (tx_writedata    ), 
    .tx_exporter_avmm_s_read                                  (tx_read         ),  
    .tx_exporter_avmm_s_write                                 (tx_write        ),     
    .tx_exporter_avmm_s_burstcount                            (tx_burstcount   ),        
    .tx_exporter_avmm_s_readdatavalid                         (tx_readdatavalid),
    .tx_exporter_avmm_s_waitrequest                           (tx_waitrequest  ),  
    .tx_exporter_avmm_s_address                               (tx_address      )     
);

endmodule