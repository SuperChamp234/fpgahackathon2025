`timescale 1ns / 1ps

module control_wrapper #(
    parameter M_AXI_ADDR_WIDTH = 32,
    parameter M_AXI_DATA_WIDTH = 32
) (
  input i_clk,
  input i_rst,
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 m_axi_aclk CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF axi_mm_00, ASSOCIATED_RESET m_axi_aresetn" *)
  input m_axi_aclk,
  input m_axi_aresetn,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_mm_00 AWADDR" *)  output [M_AXI_ADDR_WIDTH-1:0]  m_axi_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_mm_00 AWVALID" *) output                         m_axi_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_mm_00 AWREADY" *) input                          m_axi_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_mm_00 WDATA" *)   output [M_AXI_DATA_WIDTH-1:0]  m_axi_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_mm_00 WVALID" *)  output                         m_axi_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_mm_00 WREADY" *)  input                          m_axi_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_mm_00 BRESP" *)   input [1:0]                    m_axi_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_mm_00 BVALID" *)  input                          m_axi_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_mm_00 BREADY" *)  output                         m_axi_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_mm_00 ARADDR" *)  output [M_AXI_ADDR_WIDTH-1:0]  m_axi_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_mm_00 ARVALID" *) output                         m_axi_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_mm_00 ARREADY" *) input                          m_axi_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_mm_00 RDATA" *)   input [M_AXI_DATA_WIDTH-1:0]   m_axi_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_mm_00 RRESP" *)   input [1:0]                    m_axi_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_mm_00 RVALID" *)  input                          m_axi_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_mm_00 RREADY" *)  output                         m_axi_rready,
  output [31:0] enabled_tasks,
  input  [31:0] num_bytes_in_to_task,
  input start_tests,
  input [31:0] current_task_number,
  output tasks_done,
  output [31:0] num_bytes_out_from_task,
  output num_bytes_out_from_task_valid
);

  control #(
    .M_AXI_ADDR_WIDTH (M_AXI_ADDR_WIDTH),
    .M_AXI_DATA_WIDTH (M_AXI_DATA_WIDTH)
  ) control_0 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .m_axi_aclk(m_axi_aclk),
    .m_axi_aresetn(m_axi_aresetn),
    .m_axi_awaddr(m_axi_awaddr),
    .m_axi_awvalid(m_axi_awvalid),
    .m_axi_awready(m_axi_awready),
    .m_axi_wdata(m_axi_wdata),
    .m_axi_wvalid(m_axi_wvalid),
    .m_axi_wready(m_axi_wready),
    .m_axi_bresp(m_axi_bresp),
    .m_axi_bvalid(m_axi_bvalid),
    .m_axi_bready(m_axi_bready),
    .m_axi_araddr(m_axi_araddr),
    .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    .m_axi_rdata(m_axi_rdata),
    .m_axi_rresp(m_axi_rresp),
    .m_axi_rvalid(m_axi_rvalid),
    .m_axi_rready(m_axi_rready),
    .enabled_tasks(enabled_tasks),
    .num_bytes_in_to_task(num_bytes_in_to_task),
    .start_tests(start_tests),
    .tasks_done(tasks_done),
    .current_task_number(current_task_number),
    .num_bytes_out_from_task(num_bytes_out_from_task),
    .num_bytes_out_from_task_valid(num_bytes_out_from_task_valid)
  );

endmodule
