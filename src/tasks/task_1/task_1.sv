`timescale 1ns / 1ps
module task_1
#(
  parameter int TASK_INPUT_WIDTH = 16,
  parameter int TASK_OUTPUT_WIDTH = 16,
  parameter int INPUT_STREAMS     = 1,
  parameter int OUTPUT_STREAMS    = 1

)(
  input                               i_clk,
  input                               i_rst,

  input                               i_valid,
  input                               i_first,
  input                               i_last,
  input signed [TASK_INPUT_WIDTH-1:0] i_data,

  output reg                          o_valid,
  output reg                          o_last,
  output reg signed [TASK_OUTPUT_WIDTH-1:0] o_data
);

  always@(posedge i_clk) begin
    o_data  <= i_data;  // Just a dummy assignement. Replace with your code.
    o_valid <= i_valid; // Just a dummy assignement. Replace with your code.
    o_last  <= i_last;  // Just a dummy assignement. Replace with your code.
  end

endmodule
