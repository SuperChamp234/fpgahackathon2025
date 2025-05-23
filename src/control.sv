`timescale 1ns / 1ns
`include "task_parameters.svh"
import tasks_parameters::*;

parameter TASK_DIN_WIDTH = 32;
parameter TASK_DOUT_WIDTH = 32;

interface task_in_interface ();
  logic                      task_data_valid;
  logic [TASK_DIN_WIDTH-1:0] task_data;
  logic                      task_data_last;
  logic                      task_data_first;

  modport master(
      output task_data_valid, task_data, task_data_last, task_data_first
  );

  modport slave(
      input task_data_valid, task_data, task_data_last, task_data_first
  );
endinterface

interface task_out_interface ();
  logic                       task_answer_valid;
  logic [TASK_DOUT_WIDTH-1:0] task_answer_data;
  logic                       task_answer_data_last;
  logic [               31:0] task_answer_size_in_bytes;
  logic [               31:0] task_answer_latency;

  modport master(
      input task_answer_valid, task_answer_data, task_answer_data_last, task_answer_size_in_bytes, task_answer_latency
  );

  modport slave(
      output task_answer_valid, task_answer_data, task_answer_data_last, task_answer_size_in_bytes, task_answer_latency
  );
endinterface

module control #(
    parameter NUMBER_OF_TASKS = 14,
    parameter TASK_DIN_WIDTH = TASK_DIN_WIDTH,
    parameter TASK_DOUT_WIDTH = TASK_DOUT_WIDTH,
    parameter M_AXI_ADDR_WIDTH = 32,
    parameter M_AXI_DATA_WIDTH = 32,
    parameter SMEM_TV_IN_BASEADDR = 32'hA000_0000,
    parameter SMEM_TV_OUT_BASEADDR = 32'hA000_2000
) (
    //  sys
    input                               i_clk,
    input                               i_rst,
    // control signals
    input                               start_tests,
    input        [                31:0] current_task_number,
    output       [                31:0] enabled_tasks,
    input        [                31:0] num_bytes_in_to_task,
    output logic                        tasks_done,
    output       [                31:0] num_bytes_out_from_task,
    output                              num_bytes_out_from_task_valid,
    // axi master
    input                               m_axi_aclk,
    input                               m_axi_aresetn,
    output       [M_AXI_ADDR_WIDTH-1:0] m_axi_awaddr,
    output                              m_axi_awvalid,
    input                               m_axi_awready,
    output       [M_AXI_DATA_WIDTH-1:0] m_axi_wdata,
    output                              m_axi_wvalid,
    input                               m_axi_wready,
    input        [                 1:0] m_axi_bresp,
    input                               m_axi_bvalid,
    output                              m_axi_bready,
    output       [M_AXI_ADDR_WIDTH-1:0] m_axi_araddr,
    output                              m_axi_arvalid,
    input                               m_axi_arready,
    input        [M_AXI_DATA_WIDTH-1:0] m_axi_rdata,
    input        [                 1:0] m_axi_rresp,
    input                               m_axi_rvalid,
    output                              m_axi_rready
);

  task_in_interface tasks_in_interface[NUMBER_OF_TASKS:1] ();
  task_out_interface tasks_out_interface[NUMBER_OF_TASKS:1] ();

  logic [M_AXI_DATA_WIDTH-1:0] tx_fifo_data_in;
  logic [M_AXI_DATA_WIDTH-1:0] tx_fifo_addr_in;
  logic                        tx_fifo_wr_en;
  logic                        tx_fifo_full;
  logic [  TASK_DIN_WIDTH-1:0] rx_fifo_data_out;
  logic                        rx_fifo_rd_en;
  logic                        rx_fifo_empty;
  logic [M_AXI_ADDR_WIDTH-1:0] req_addr_fifo_in;
  logic                        req_addr_fifo_wr_en;
  logic                        req_addr_fifo_full;

  logic                        task_manager_done;
  logic                        task_manager_done_r;
  logic                        tx_fifo_empty;

  logic rx_fifo_flush;
  logic rx_fifo_data_valid;
  logic tv_in_last;
  logic rst_data_width_converter;
  
  always_ff @(posedge i_clk) begin
    if (task_manager_done)
      task_manager_done_r <= 1'b1;
    else if (task_manager_done_r && tx_fifo_empty) begin
      task_manager_done_r <= 1'b0;
      tasks_done <= 1'b1;
    end else begin
      task_manager_done_r <= task_manager_done_r;
      tasks_done <= 1'b0;
    end

    if (i_rst) begin
      task_manager_done_r <= 1'b0;
      tasks_done <= 1'b0;
    end
  end


  axi_mm_master #(
    .C_M_AXI_ADDR_WIDTH(M_AXI_ADDR_WIDTH),
    .C_M_AXI_DATA_WIDTH(M_AXI_DATA_WIDTH),
    .C_TX_FIFO_DEPTH (16),
    .C_RX_FIFO_DEPTH (512),
    .C_REQ_FIFO_DEPTH(512)
  ) axi_mm_0 (
    .M_AXI_ACLK(m_axi_aclk),
    .M_AXI_ARESETN(m_axi_aresetn),
    .M_AXI_AWADDR(m_axi_awaddr),
    .M_AXI_AWVALID(m_axi_awvalid),
    .M_AXI_AWREADY(m_axi_awready),
    .M_AXI_WDATA(m_axi_wdata),
    .M_AXI_WVALID(m_axi_wvalid),
    .M_AXI_WREADY(m_axi_wready),
    .M_AXI_BRESP(m_axi_bresp),
    .M_AXI_BVALID(m_axi_bvalid),
    .M_AXI_BREADY(m_axi_bready),
    .M_AXI_ARADDR(m_axi_araddr),
    .M_AXI_ARVALID(m_axi_arvalid),
    .M_AXI_ARREADY(m_axi_arready),
    .M_AXI_RDATA(m_axi_rdata),
    .M_AXI_RRESP(m_axi_rresp),
    .M_AXI_RVALID(m_axi_rvalid),
    .M_AXI_RREADY(m_axi_rready),
    .TX_FIFO_DATA_IN(tx_fifo_data_in),
    .TX_FIFO_ADDR_IN(tx_fifo_addr_in),
    .TX_FIFO_WR_EN(tx_fifo_wr_en),
    .TX_FIFO_FULL(tx_fifo_full),
    .TX_FIFO_EMPTY(tx_fifo_empty),
    .RX_FIFO_DATA_OUT(rx_fifo_data_out),
    .RX_FIFO_RD_EN(rx_fifo_rd_en),
    .RX_FIFO_EMPTY(rx_fifo_empty),
    .RX_FIFO_DATA_VALID(rx_fifo_data_valid),
    .REQ_ADDR_FIFO_IN(req_addr_fifo_in),
    .REQ_ADDR_FIFO_WR_EN(req_addr_fifo_wr_en),
    .REQ_ADDR_FIFO_FULL(req_addr_fifo_full),
    .RX_FIFO_FLUSH(rx_fifo_flush)
  );

  task_manager #(
    .NUMBER_OF_TASKS(NUMBER_OF_TASKS),
    .TASK_DIN_WIDTH(TASK_DIN_WIDTH),
    .TASK_DOUT_WIDTH(TASK_DOUT_WIDTH),
    .M_AXI_DATA_WIDTH(M_AXI_DATA_WIDTH),
    .M_AXI_ADDR_WIDTH(M_AXI_ADDR_WIDTH),
    .SMEM_TV_IN_BASEADDR(SMEM_TV_IN_BASEADDR),
    .SMEM_TV_OUT_BASEADDR(SMEM_TV_OUT_BASEADDR)
  ) task_manager_0 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .tim (tasks_in_interface),
    .tom (tasks_out_interface),
    .TV_IN_DATA   (rx_fifo_data_out),
    .TV_IN_FIFO_RD_EN  (rx_fifo_rd_en),
    .TV_IN_FIFO_NOT_EMPTY(~rx_fifo_empty),
    .TV_OUT_DATA  (tx_fifo_data_in),
    .TV_OUT_ADDR  (tx_fifo_addr_in),
    .TV_OUT_WR_EN (tx_fifo_wr_en),
    .TV_OUT_READY (~tx_fifo_full),
    .TV_REQ_ADDR  (req_addr_fifo_in),
    .TV_REQ_READY (~req_addr_fifo_full),
    .TV_REQ_WR_EN (req_addr_fifo_wr_en),
    .enabled_tasks(enabled_tasks),
    .start_tests  (start_tests),
    .tasks_done   (task_manager_done),
    .current_task_number(current_task_number),
    .num_bytes_in_to_task(num_bytes_in_to_task),
    .num_bytes_out_from_task(num_bytes_out_from_task),
    .num_bytes_out_from_task_valid(num_bytes_out_from_task_valid),
    .o_rst_axi_mm_fifo(rx_fifo_flush),
    .TV_IN_DATA_VALID(rx_fifo_data_valid),
    .tv_in_last(tv_in_last),
    .rst_data_width_converter(rst_data_width_converter)
  );


  task_1_wrapper #(
    .TASK_INPUT_WIDTH(TASK_1_DATA_WIDTH_IN),
    .TASK_OUTPUT_WIDTH(TASK_1_DATA_WIDTH_OUT),
    .INPUT_STREAMS(TASK_1_INPUT_STREAMS),
    .OUTPUT_STREAMS(TASK_1_OUTPUT_STREAMS),
    .MAX_SAMPLES_IN(TASK_1_MAX_SAMPLES_IN)
  ) task_1 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .tis  (tasks_in_interface[1]),
    .tos  (tasks_out_interface[1]),
    .tv_in_last(tv_in_last),
    .i_rst_data_width_converter(rst_data_width_converter)
  );

  task_2_wrapper #(
    .TASK_INPUT_WIDTH(TASK_2_DATA_WIDTH_IN),
    .TASK_OUTPUT_WIDTH(TASK_2_DATA_WIDTH_OUT),
    .INPUT_STREAMS(TASK_2_INPUT_STREAMS),
    .OUTPUT_STREAMS(TASK_2_OUTPUT_STREAMS),
    .MAX_SAMPLES_IN(TASK_2_MAX_SAMPLES_IN)
  ) task_2 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .tis  (tasks_in_interface[2]),
    .tos  (tasks_out_interface[2]),
    .tv_in_last(tv_in_last),
    .i_rst_data_width_converter(rst_data_width_converter)
  );

  task_3_wrapper #(
    .TASK_INPUT_WIDTH(TASK_3_DATA_WIDTH_IN),
    .TASK_OUTPUT_WIDTH(TASK_3_DATA_WIDTH_OUT),
    .INPUT_STREAMS(TASK_3_INPUT_STREAMS),
    .OUTPUT_STREAMS(TASK_3_OUTPUT_STREAMS),
    .MAX_SAMPLES_IN(TASK_3_MAX_SAMPLES_IN)
  ) task_3 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .tis  (tasks_in_interface[3]),
    .tos  (tasks_out_interface[3]),
    .tv_in_last(tv_in_last),
    .i_rst_data_width_converter(rst_data_width_converter)
  );

  task_4_wrapper #(
    .TASK_INPUT_WIDTH(TASK_4_DATA_WIDTH_IN),
    .TASK_OUTPUT_WIDTH(TASK_4_DATA_WIDTH_OUT),
    .INPUT_STREAMS(TASK_4_INPUT_STREAMS),
    .OUTPUT_STREAMS(TASK_4_OUTPUT_STREAMS),
    .MAX_SAMPLES_IN(TASK_4_MAX_SAMPLES_IN)
  ) task_4 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .tis  (tasks_in_interface[4]),
    .tos  (tasks_out_interface[4]),
    .tv_in_last(tv_in_last),
    .i_rst_data_width_converter(rst_data_width_converter)
  );

  task_5_wrapper #(
    .TASK_INPUT_WIDTH(TASK_5_DATA_WIDTH_IN),
    .TASK_OUTPUT_WIDTH(TASK_5_DATA_WIDTH_OUT),
    .INPUT_STREAMS(TASK_5_INPUT_STREAMS),
    .OUTPUT_STREAMS(TASK_5_OUTPUT_STREAMS),
    .MAX_SAMPLES_IN(TASK_5_MAX_SAMPLES_IN)
  ) task_5 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .tis  (tasks_in_interface[5]),
    .tos  (tasks_out_interface[5]),
    .tv_in_last(tv_in_last),
    .i_rst_data_width_converter(rst_data_width_converter)
  );

  task_6_wrapper #(
    .TASK_INPUT_WIDTH(TASK_6_DATA_WIDTH_IN),
    .TASK_OUTPUT_WIDTH(TASK_6_DATA_WIDTH_OUT),
    .INPUT_STREAMS(TASK_6_INPUT_STREAMS),
    .OUTPUT_STREAMS(TASK_6_OUTPUT_STREAMS),
    .MAX_SAMPLES_IN(TASK_6_MAX_SAMPLES_IN)
  ) task_6 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .tis  (tasks_in_interface[6]),
    .tos  (tasks_out_interface[6]),
    .tv_in_last(tv_in_last),
    .i_rst_data_width_converter(rst_data_width_converter)
  );

  task_7_wrapper #(
    .TASK_INPUT_WIDTH(TASK_7_DATA_WIDTH_IN),
    .TASK_OUTPUT_WIDTH(TASK_7_DATA_WIDTH_OUT),
    .INPUT_STREAMS(TASK_7_INPUT_STREAMS),
    .OUTPUT_STREAMS(TASK_7_OUTPUT_STREAMS),
    .MAX_SAMPLES_IN(TASK_7_MAX_SAMPLES_IN)
  ) task_7 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .tis  (tasks_in_interface[7]),
    .tos  (tasks_out_interface[7]),
    .tv_in_last(tv_in_last),
    .i_rst_data_width_converter(rst_data_width_converter)
  );

  task_8_wrapper #(
    .TASK_INPUT_WIDTH(TASK_8_DATA_WIDTH_IN),
    .TASK_OUTPUT_WIDTH(TASK_8_DATA_WIDTH_OUT),
    .INPUT_STREAMS(TASK_8_INPUT_STREAMS),
    .OUTPUT_STREAMS(TASK_8_OUTPUT_STREAMS),
    .MAX_SAMPLES_IN(TASK_8_MAX_SAMPLES_IN)
  ) task_8 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .tis  (tasks_in_interface[8]),
    .tos  (tasks_out_interface[8]),
    .tv_in_last(tv_in_last),
    .i_rst_data_width_converter(rst_data_width_converter)
  );

  task_9_wrapper #(
    .TASK_INPUT_WIDTH(TASK_9_DATA_WIDTH_IN),
    .TASK_OUTPUT_WIDTH(TASK_9_DATA_WIDTH_OUT),
    .INPUT_STREAMS(TASK_9_INPUT_STREAMS),
    .OUTPUT_STREAMS(TASK_9_OUTPUT_STREAMS),
    .MAX_SAMPLES_IN(TASK_9_MAX_SAMPLES_IN)
  ) task_9 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .tis  (tasks_in_interface[9]),
    .tos  (tasks_out_interface[9]),
    .tv_in_last(tv_in_last),
    .i_rst_data_width_converter(rst_data_width_converter)
  );

  task_10_wrapper #(
    .TASK_INPUT_WIDTH(TASK_10_DATA_WIDTH_IN),
    .TASK_OUTPUT_WIDTH(TASK_10_DATA_WIDTH_OUT),
    .INPUT_STREAMS(TASK_10_INPUT_STREAMS),
    .OUTPUT_STREAMS(TASK_10_OUTPUT_STREAMS),
    .MAX_SAMPLES_IN(TASK_10_MAX_SAMPLES_IN)
  ) task_10 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .tis  (tasks_in_interface[10]),
    .tos  (tasks_out_interface[10]),
    .tv_in_last(tv_in_last),
    .i_rst_data_width_converter(rst_data_width_converter)
  );

  task_11_wrapper #(
    .TASK_INPUT_WIDTH(TASK_11_DATA_WIDTH_IN),
    .TASK_OUTPUT_WIDTH(TASK_11_DATA_WIDTH_OUT),
    .INPUT_STREAMS(TASK_11_INPUT_STREAMS),
    .OUTPUT_STREAMS(TASK_11_OUTPUT_STREAMS),
    .MAX_SAMPLES_IN(TASK_11_MAX_SAMPLES_IN)
  ) task_11 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .tis  (tasks_in_interface[11]),
    .tos  (tasks_out_interface[11]),
    .tv_in_last(tv_in_last),
    .i_rst_data_width_converter(rst_data_width_converter)
  );

  task_12_wrapper #(
    .TASK_INPUT_WIDTH(TASK_12_DATA_WIDTH_IN),
    .TASK_OUTPUT_WIDTH(TASK_12_DATA_WIDTH_OUT),
    .INPUT_STREAMS(TASK_12_INPUT_STREAMS),
    .OUTPUT_STREAMS(TASK_12_OUTPUT_STREAMS),
    .MAX_SAMPLES_IN(TASK_12_MAX_SAMPLES_IN)
  ) task_12 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .tis  (tasks_in_interface[12]),
    .tos  (tasks_out_interface[12]),
    .tv_in_last(tv_in_last),
    .i_rst_data_width_converter(rst_data_width_converter)
  );

  task_13_wrapper #(
    .TASK_INPUT_WIDTH(TASK_13_DATA_WIDTH_IN),
    .TASK_OUTPUT_WIDTH(TASK_13_DATA_WIDTH_OUT),
    .INPUT_STREAMS(TASK_13_INPUT_STREAMS),
    .OUTPUT_STREAMS(TASK_13_OUTPUT_STREAMS),
    .MAX_SAMPLES_IN(TASK_13_MAX_SAMPLES_IN)
  ) task_13 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .tis  (tasks_in_interface[13]),
    .tos  (tasks_out_interface[13]),
    .tv_in_last(tv_in_last),
    .i_rst_data_width_converter(rst_data_width_converter)
  );

  task_14_wrapper #(
    .TASK_INPUT_WIDTH(TASK_14_DATA_WIDTH_IN),
    .TASK_OUTPUT_WIDTH(TASK_14_DATA_WIDTH_OUT),
    .INPUT_STREAMS(TASK_14_INPUT_STREAMS),
    .OUTPUT_STREAMS(TASK_14_OUTPUT_STREAMS),
    .MAX_SAMPLES_IN(TASK_14_MAX_SAMPLES_IN)
  ) task_14 (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .tis  (tasks_in_interface[14]),
    .tos  (tasks_out_interface[14]),
    .tv_in_last(tv_in_last),
    .i_rst_data_width_converter(rst_data_width_converter)
  );

endmodule
