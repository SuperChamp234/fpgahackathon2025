module control_wrapper_tb #(
  parameter AXI_ADDR_WIDTH = 32,
  parameter AXI_DATA_WIDTH = 32
)(
  input         clk,
  input         reset,
  output [31:0] enabled_tasks,
  input  [31:0] num_bytes_in_to_task,
  input         start_tests,
  input  [31:0] current_task_number,
  output        tasks_done,
  output [31:0] num_bytes_out_from_task,
  output        num_bytes_out_from_task_valid
);

logic resetn;
logic [AXI_ADDR_WIDTH-1:0] m_axi_awaddr, m_axi_araddr;
logic [AXI_DATA_WIDTH-1:0] m_axi_wdata, m_axi_rdata;
logic [1:0] m_axi_rresp, m_axi_bresp;
logic m_axi_awready, m_axi_awvalid, m_axi_wvalid, m_axi_wready;
logic m_axi_bready, m_axi_bvalid, m_axi_arvalid, m_axi_arready;
logic m_axi_rvalid, m_axi_rready;

assign resetn = ~reset;

control_wrapper #(
  .M_AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
  .M_AXI_DATA_WIDTH(AXI_DATA_WIDTH)
) control_wrapper0 (
  .i_clk        (clk),
  .i_rst        (reset),
  .m_axi_aclk   (clk),
  .m_axi_aresetn(resetn),
  .m_axi_awaddr (m_axi_awaddr),
  .m_axi_awvalid(m_axi_awvalid),
  .m_axi_awready(m_axi_awready),
  .m_axi_wdata  (m_axi_wdata),
  .m_axi_wvalid (m_axi_wvalid),
  .m_axi_wready (m_axi_wready),
  .m_axi_bresp  (m_axi_bresp),
  .m_axi_bvalid (m_axi_bvalid),
  .m_axi_bready (m_axi_bready),
  .m_axi_araddr (m_axi_araddr),
  .m_axi_arvalid(m_axi_arvalid),
  .m_axi_arready(m_axi_arready),
  .m_axi_rdata  (m_axi_rdata),
  .m_axi_rresp  (m_axi_rresp),
  .m_axi_rvalid (m_axi_rvalid),
  .m_axi_rready (m_axi_rready),
  .enabled_tasks                 (enabled_tasks),
  .num_bytes_in_to_task          (num_bytes_in_to_task),
  .start_tests                   (start_tests),
  .current_task_number           (current_task_number),
  .tasks_done                    (tasks_done),
  .num_bytes_out_from_task       (num_bytes_out_from_task),
  .num_bytes_out_from_task_valid (num_bytes_out_from_task_valid)
);

axi_vip_0 s_axi_vip (
  .aclk         (clk),
  .aresetn      (resetn),
  .s_axi_awaddr (m_axi_awaddr),
  .s_axi_awvalid(m_axi_awvalid),
  .s_axi_awready(m_axi_awready),
  .s_axi_wdata  (m_axi_wdata),
  .s_axi_wvalid (m_axi_wvalid),
  .s_axi_wready (m_axi_wready),
  .s_axi_bresp  (m_axi_bresp),
  .s_axi_bvalid (m_axi_bvalid),
  .s_axi_bready (m_axi_bready),
  .s_axi_araddr (m_axi_araddr),
  .s_axi_arvalid(m_axi_arvalid),
  .s_axi_arready(m_axi_arready),
  .s_axi_rdata  (m_axi_rdata),
  .s_axi_rresp  (m_axi_rresp),
  .s_axi_rvalid (m_axi_rvalid),
  .s_axi_rready (m_axi_rready)
);

endmodule
