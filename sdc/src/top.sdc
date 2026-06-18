#**************************************************************
# Create Clock
#**************************************************************
create_clock -name pll_50mhz -period 20.000 [get_pins {u_my_pcie|pll_0|altera_pll_i|outclk_wire[0]~CLKENA0|outclk}]
create_clock -period 10 -name PCIE_REFCLK_p [get_ports {PCIE_REFCLK_p}]
set pcie_app_clk {u_my_pcie|pcie_cv_hip_avmm_0|c5_hip_ast|altpcie_av_hip_ast_hwtcl|altpcie_av_hip_128bit_atom|g_cavhip.arriav_hd_altpe2_hip_top|coreclkout}

#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks


#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty


#**************************************************************
# Set False Path
#**************************************************************
set_false_path -from [get_ports {PCIE_PERST_n}]
set_false_path -from [get_ports {CPU_RESET_n}]
set_false_path -from [get_ports {KEY[*]}]
set_false_path -to   [get_ports {LED[*]}]

set_false_path -from [get_pins -hierarchical {clock_50_rstn_rr|q}]
set_false_path -from [get_pins -hierarchical {clock_125_rstn_rr|q}]
set_false_path -from [get_pins {u_dma_testenv_top|u_avmm_dma_top|u_avmm_dma_csr|dma_resetn_o|q}]
set_false_path -from [get_clocks ${pcie_app_clk}] -to [get_clocks pll_50mhz]
set_false_path -from [get_clocks pll_50mhz] -to [get_clocks ${pcie_app_clk}]
