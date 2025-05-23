
`timescale 1 ns / 1 ps

module control_regs #
(
  parameter integer C_S00_AXI_DATA_WIDTH = 32,
  parameter integer C_S00_AXI_ADDR_WIDTH = 5
)(
  input                               s00_axi_aclk,
  input                               s00_axi_aresetn,
  input  [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
  input                               s00_axi_awvalid,
  output                              s00_axi_awready,
  input  [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
  input                               s00_axi_wvalid,
  output                              s00_axi_wready,
  output [1 : 0]                      s00_axi_bresp,
  output                              s00_axi_bvalid,
  input                               s00_axi_bready,
  input  [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
  input                               s00_axi_arvalid,
  output                              s00_axi_arready,
  output [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
  output [1 : 0]                      s00_axi_rresp,
  output                              s00_axi_rvalid,
  input                               s00_axi_rready,
  output                              tv_in_ready,
  input                               pl_ready,
  input                               pl_ready_wr_en,
  input                               tv_out_ready,
  input                               tv_out_ready_wr_en,
  input [C_S00_AXI_DATA_WIDTH-1 : 0]  enabled_tasks,
  input                               enabled_tasks_wr_en,
  output                              reg_wr_busy,
  output [C_S00_AXI_DATA_WIDTH-1 : 0] current_task_number,
  output                              aux_pl_res,
  output                              tv_out_rcv_ack,
  output [C_S00_AXI_DATA_WIDTH-1 : 0] num_bytes_in_to_task,
  input  [C_S00_AXI_DATA_WIDTH-1 : 0] num_bytes_out_from_task,
  input                               num_bytes_out_from_task_valid
);

  wire reset_reg;

control_regs_S_AXI # ( 
  .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
  .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
) control_regs_S_AXI_inst (
  .S_AXI_ACLK(s00_axi_aclk),
  .S_AXI_ARESETN(s00_axi_aresetn),
  .S_AXI_AWADDR(s00_axi_awaddr),
  .S_AXI_AWVALID(s00_axi_awvalid),
  .S_AXI_AWREADY(s00_axi_awready),
  .S_AXI_WDATA(s00_axi_wdata),
  .S_AXI_WVALID(s00_axi_wvalid),
  .S_AXI_WREADY(s00_axi_wready),
  .S_AXI_BRESP(s00_axi_bresp),
  .S_AXI_BVALID(s00_axi_bvalid),
  .S_AXI_BREADY(s00_axi_bready),
  .S_AXI_ARADDR(s00_axi_araddr),
  .S_AXI_ARVALID(s00_axi_arvalid),
  .S_AXI_ARREADY(s00_axi_arready),
  .S_AXI_RDATA(s00_axi_rdata),
  .S_AXI_RRESP(s00_axi_rresp),
  .S_AXI_RVALID(s00_axi_rvalid),
  .S_AXI_RREADY(s00_axi_rready),
  .REG_WR_BUSY(reg_wr_busy),
   //REG0 pl_ready 1 bit input
  .REG0_IN(pl_ready),
  .REG0_WR_EN(pl_ready_wr_en),
  //REG1 enabled tasks 32 bits input
  .REG1_IN(enabled_tasks),
  .REG1_WR_EN(enabled_tasks_wr_en),
  //REG2 current_task 32 bits output
  .REG2_OUT(current_task_number),
  //REG3 tv_in_ready 1 bit output
  .REG3_OUT(tv_in_ready),
  //REG4 tv_output_ready 1 bit input
  .REG4_IN(tv_out_ready),
  .REG4_WR_EN(tv_out_ready_wr_en),
   //REG5 pl reset
  .REG5_OUT(reset_reg),
  //REG6 num_bytes_in_to_task
  .REG6_OUT(num_bytes_in_to_task),
  .REG7_IN(num_bytes_out_from_task),
  .REG7_WR_EN(num_bytes_out_from_task_valid),
  .REG8_OUT(tv_out_rcv_ack)
);

reset_delay reset_delay_0 (
  .i_clk(s00_axi_aclk),
  .i_rstn(s00_axi_aresetn),
  .i_enb(reset_reg),
  .o_q(aux_pl_res)
);

endmodule
