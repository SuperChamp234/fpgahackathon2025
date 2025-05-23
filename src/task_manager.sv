`timescale 1ns / 1ns
`include "task_enabler_pkg.svh"
import task_enabler_pkg::*;

module task_manager
  #(parameter NUMBER_OF_TASKS  = 16, // MAXIMUM number 32!
    parameter TASK_DIN_WIDTH   = 8,
    parameter TASK_DOUT_WIDTH  = 32,
    parameter M_AXI_DATA_WIDTH = 32,
    parameter M_AXI_ADDR_WIDTH = 32,
    parameter SMEM_TV_IN_BASEADDR  = 32'hA000_0000,
    parameter SMEM_TV_OUT_BASEADDR = 32'hA000_2000
  ) (
    // sys 
    input         i_clk,
    input         i_rst,
    input         start_tests,
    input  [31:0] current_task_number,
    output        tasks_done,
    output [31:0] enabled_tasks,
    input  [31:0] num_bytes_in_to_task,
    output [31:0] num_bytes_out_from_task,
    output        num_bytes_out_from_task_valid,
    // Test vectors incoming from AXI interface to tasks 
    input [TASK_DIN_WIDTH-1:0] TV_IN_DATA,
    output logic               TV_IN_FIFO_RD_EN,
    input                      TV_IN_FIFO_NOT_EMPTY,
    input                      TV_IN_DATA_VALID,
    // Test vectors outgoing from tasks to AXI interface 
    output logic [M_AXI_DATA_WIDTH-1:0] TV_OUT_DATA,
    output logic [M_AXI_DATA_WIDTH-1:0] TV_OUT_ADDR,
    output logic                        TV_OUT_WR_EN,
    input                               TV_OUT_READY,
    // Test vectors request
    output logic [M_AXI_ADDR_WIDTH-1:0] TV_REQ_ADDR,
    input                               TV_REQ_READY,
    output logic                        TV_REQ_WR_EN,
    output logic                        o_rst_axi_mm_fifo,
    // Task interfaces
    task_in_interface.master  tim [NUMBER_OF_TASKS:1],
    task_out_interface.master tom [NUMBER_OF_TASKS:1],
    output logic tv_in_last,
    output logic rst_data_width_converter
  );

  localparam TASK_DONE_DELAY = 10000; //f=100MHz, t=10ns, 10ns*10000=100us

typedef enum {
  IDLE,
  SEND_TV_IN,
  SEND_TV_OUT,
  TASK_DONE
} state_enum;

state_enum state;
state_enum next_state;

assign enabled_tasks = {16'b0, enable};

reg [$clog2(TASK_DONE_DELAY)-1:0] task_done_cnt;
reg w_task_done;
wire [TASK_DOUT_WIDTH-1:0] task_answer_data;
reg [31:0] task_answer_size_in_bytes;
reg task_data_valid;
reg task_manager_ready;
wire task_answer_valid;
wire task_answer_data_last;
wire task_data_request;
reg [3:0] tv_out_wr_en_reg;

reg [4:0] granted_task_number;
reg [31:0] tv_req_cnt, tv_in_cnt, tv_out_cnt;
reg tv_req_sent, tv_in_sent;
reg tv_out_last;
reg tv_out_sent;

reg [NUMBER_OF_TASKS:1] [TASK_DOUT_WIDTH-1:0] tom_task_answer_data;
reg [NUMBER_OF_TASKS:1]                       tom_task_answer_valid;
reg [NUMBER_OF_TASKS:1]                       tom_task_answer_data_last;
reg [NUMBER_OF_TASKS:1] [31:0]                tom_task_answer_size_in_bytes;
reg [NUMBER_OF_TASKS:1] [31:0]                tom_task_answer_latency;

genvar i, j;

logic [31:0] num_empty_bytes_in_last_sample;
logic [31:0] num_valid_bytes_in_last_sample;

reg [31:0] num_bytes_in_to_task_adj;

reg task_manager_ready_del_2;
reg task_manager_ready_del;

wire [31:0] task_in_data;
wire task_in_valid;
wire task_in_last;
wire task_in_first;

wire [31:0] w_latency;
wire [31:0] w_data_from_task;
wire w_valid_from_task;
wire w_last_from_task;

assign num_valid_bytes_in_last_sample = (num_bytes_in_to_task % 4) ? num_bytes_in_to_task % 4 : 4;
assign num_empty_bytes_in_last_sample = 4 - num_valid_bytes_in_last_sample;
assign num_bytes_in_to_task_adj = num_bytes_in_to_task + num_empty_bytes_in_last_sample;
assign task_answer_size_in_bytes = granted_task_number==0 ? 0 : tom_task_answer_size_in_bytes[granted_task_number];

assign w_data_from_task     = granted_task_number==0 ? 0 : tom_task_answer_data[granted_task_number];
assign w_valid_from_task    = granted_task_number==0 ? 0 : tom_task_answer_valid[granted_task_number];
assign w_last_from_task     = granted_task_number==0 ? 0 : tom_task_answer_data_last[granted_task_number];
assign w_latency            = granted_task_number==0 ? 0 : tom_task_answer_latency[granted_task_number];

assign tasks_done = w_task_done;
assign granted_task_number = current_task_number[4:0];
assign task_manager_ready = task_answer_valid && TV_OUT_READY;
assign num_bytes_out_from_task_valid = (state == SEND_TV_OUT && tv_out_last);
assign num_bytes_out_from_task = task_answer_size_in_bytes;


always_ff @(posedge i_clk) begin
  TV_OUT_DATA <= task_answer_data;
  tv_out_last <= task_answer_data_last;
  TV_OUT_WR_EN <= tv_out_wr_en_reg[3];
end

always_ff @(posedge i_clk) state <= next_state;
always_ff @(posedge i_clk) w_task_done <= (task_done_cnt==0) ? 1'b1 : 1'b0;

always_ff @(posedge i_clk) begin : tv_out_write_enable_pipeline
  if (i_rst == 1)
    tv_out_wr_en_reg <= '0;
  else
    tv_out_wr_en_reg <= {tv_out_wr_en_reg[2] && task_answer_valid, tv_out_wr_en_reg[1] && task_answer_valid, tv_out_wr_en_reg[0] && task_answer_valid, task_manager_ready};

end : tv_out_write_enable_pipeline


always_ff @(posedge i_clk) begin
  if (i_rst)
    tv_out_sent <= 1'b0;
  else begin
    if (state == SEND_TV_OUT)
      tv_out_sent <= tv_out_last && TV_OUT_WR_EN;
    else
      tv_out_sent <= 1'b0;
  end
end


always_ff @(posedge i_clk) begin : task_done_control
  if ((state == TASK_DONE) && (task_done_cnt > 0) )
    task_done_cnt <= task_done_cnt-1;
  else
    task_done_cnt <= TASK_DONE_DELAY;
end : task_done_control


always_ff @(posedge i_clk) begin
  task_manager_ready_del <= task_manager_ready;
  task_manager_ready_del_2 <= task_manager_ready_del;
end


generate for (i=1; i <= NUMBER_OF_TASKS; i++) begin : TIM_TOM1
    always_ff @(posedge i_clk) begin
      if (i_rst)
        tom_task_answer_valid[i] <= 0;
      else
        tom_task_answer_valid[i] <= tom[i].task_answer_valid;
    end

    always_ff @(posedge i_clk) begin
      tom_task_answer_data[i]          <= tom[i].task_answer_data;
      tom_task_answer_data_last[i]     <= tom[i].task_answer_data_last;
      tom_task_answer_size_in_bytes[i] <= tom[i].task_answer_size_in_bytes;
      tom_task_answer_latency[i]       <= tom[i].task_answer_latency;
    end
  end : TIM_TOM1
endgenerate

generate for (j=1; j <= NUMBER_OF_TASKS; j++) begin : TIM_TOM2
  always_ff @(posedge i_clk) begin
    if (i_rst)
      tim[j].task_data_valid <= 0;
    else begin
      if (j==granted_task_number)
        tim[j].task_data_valid <= task_in_valid;
      else
        tim[j].task_data_valid <= 0;
    end
  end

  always_ff @(posedge i_clk) begin
    if (j==granted_task_number) begin
      tim[j].task_data       <= task_in_data;
      tim[j].task_data_last  <= task_in_last;
      tim[j].task_data_first <= task_in_first;
    end else begin
      tim[j].task_data       <= '0;
      tim[j].task_data_last  <=  0;
      tim[j].task_data_first <=  0;
    end
  end
end : TIM_TOM2
endgenerate

assign rst_data_width_converter = (next_state == SEND_TV_IN);

always_comb begin : fsm_transitions
  if (i_rst)
    next_state = IDLE;
  else begin
    case(state)
      IDLE: begin
        if (start_tests == 1) next_state = SEND_TV_IN;
        else next_state = state;
      end
      SEND_TV_IN: begin
        if (tv_in_sent == 1) next_state = SEND_TV_OUT;
        else next_state = state;
      end
      SEND_TV_OUT: begin
        if (tv_out_sent == 1) next_state = TASK_DONE;
        else next_state = state;
      end
      TASK_DONE: begin
        if (w_task_done == 1) next_state = IDLE;
        else next_state = state;
      end
      default: next_state = IDLE;
    endcase
  end
end : fsm_transitions


always_ff @(posedge i_clk) begin : tv_req_addr_gen_wr_en_gen
  if (i_rst == 1) begin
    TV_REQ_ADDR  <= 0;
    TV_REQ_WR_EN <= 0;
  end else begin
    if (state == SEND_TV_IN && tv_req_sent == 0 ) begin
      if (TV_REQ_READY == 1) begin
        TV_REQ_ADDR <= SMEM_TV_IN_BASEADDR+tv_req_cnt*4;
      end else begin
        TV_REQ_ADDR <= TV_REQ_ADDR;
      end
      TV_REQ_WR_EN <= TV_REQ_READY;
    end else begin
      TV_REQ_ADDR <= 0;
      TV_REQ_WR_EN <= 0;
    end
  end
end : tv_req_addr_gen_wr_en_gen


always_ff @(posedge i_clk) begin : tv_in_rd_en_gen
  if (i_rst == 1) begin
    TV_IN_FIFO_RD_EN <= 0;
  end else begin
    if (state == SEND_TV_IN && tv_in_sent == 0) begin
      TV_IN_FIFO_RD_EN  <= task_data_request;
    end else begin
      TV_IN_FIFO_RD_EN  <= 0;
    end
  end
end : tv_in_rd_en_gen


always_ff @(posedge i_clk) begin : tv_req_cnt_sent_control
  case (state)
    default: begin
      tv_req_cnt  <= 0;
      tv_req_sent <= 0;
    end
    SEND_TV_IN: begin
      if (TV_REQ_READY == 1)
        if (tv_req_cnt < ((num_bytes_in_to_task_adj-1) >> 2)) begin
          tv_req_cnt <= tv_req_cnt + 1;
          tv_req_sent <= 0;
        end else begin
          tv_req_cnt <= tv_req_cnt;
          tv_req_sent <= 1;
        end
    end
  endcase
end : tv_req_cnt_sent_control


always_ff @(posedge i_clk) begin : flush_axi_mm_rcv_fifo
  o_rst_axi_mm_fifo <= 0;
  if (TV_IN_FIFO_RD_EN == 1 && TV_IN_FIFO_NOT_EMPTY == 1)
    if (tv_in_cnt == num_bytes_in_to_task_adj/4-1)
      o_rst_axi_mm_fifo <= 1;
  if (o_rst_axi_mm_fifo == 1)
    o_rst_axi_mm_fifo <= 0;
end


always_comb begin : task_data_valid_control
  if (i_rst == 1)
    task_data_valid = 0;
  else begin
    if (state == SEND_TV_IN && tv_in_cnt <= num_bytes_in_to_task_adj/4)
      task_data_valid = TV_IN_DATA_VALID;
    else
      task_data_valid = 0;
  end
end


always_ff @(posedge i_clk) begin : tv_in_cnt_sent_last_control
  case (state)
    default: begin
      tv_in_cnt   <= 0;
      tv_in_sent  <= 0;
      tv_in_last  <= 0;
    end
    SEND_TV_IN: begin
      if (TV_IN_FIFO_RD_EN == 1 && TV_IN_FIFO_NOT_EMPTY == 1) begin
        if (tv_in_cnt <= num_bytes_in_to_task_adj/4)
          tv_in_cnt <= tv_in_cnt + 1;
        else
          tv_in_cnt <= tv_in_cnt;

        if (tv_in_cnt == num_bytes_in_to_task_adj/4-1) begin
          tv_in_sent <= 1;
          tv_in_last <= 1;
        end else begin
          tv_in_sent <= 0;
          tv_in_last <= 0;
        end

      end else
        if (tv_in_cnt == num_bytes_in_to_task_adj/4)
          tv_in_last <= 0; 
    end
  endcase
end : tv_in_cnt_sent_last_control


always_ff @(posedge i_clk) begin : tv_out_cnt_sent_control
  case (state)
    default: begin
      tv_out_cnt  <= 0;
      TV_OUT_ADDR <= SMEM_TV_OUT_BASEADDR;
    end
    SEND_TV_OUT: begin
      if (tv_out_wr_en_reg[3]) begin
        tv_out_cnt  <= tv_out_cnt + 1;
        TV_OUT_ADDR <= SMEM_TV_OUT_BASEADDR+tv_out_cnt*4;
      end else begin
        tv_out_cnt  <= tv_out_cnt;
        TV_OUT_ADDR <= TV_OUT_ADDR;
      end
    end
  endcase
end : tv_out_cnt_sent_control

  task_in #(
      .FIFO_DEPTH_IN_BYTES(8192)
  ) task_in (
      .i_clk(i_clk),
      .i_rst(i_rst),
      .current_task_number(current_task_number),
      .num_valid_bytes_in_last_sample(num_valid_bytes_in_last_sample),
      .i_tdata_valid(task_data_valid),
      .i_tdata(TV_IN_DATA),
      .i_tdata_last(tv_in_last),
      .i_output_last(task_answer_data_last),
      .o_tready(task_data_request),
      .o_data(task_in_data),
      .o_valid(task_in_valid),
      .o_first(task_in_first),
      .o_last(task_in_last)
  );

  task_out #(
      .WRITE_DATA_WIDTH(32),
      .READ_DATA_WIDTH(32),
      .FIFO_SIZE(8192)
  ) task_out (
      .i_clk(i_clk),
      .i_rst(i_rst),
      .i_tmanager_ready(task_manager_ready_del_2),
      .i_lat(w_latency),
      .i_data(w_data_from_task),
      .i_data_valid(w_valid_from_task),
      .i_task_last(w_last_from_task),
      .i_input_last(tv_in_last),
      .o_tanswer_valid(task_answer_valid),
      .o_tdata(task_answer_data),
      .o_tanswer_data_last(task_answer_data_last)
  );

endmodule
