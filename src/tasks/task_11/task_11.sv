`timescale 1ns / 1ps
module task_11 #(
    parameter int TASK_INPUT_WIDTH  = 8,
    parameter int TASK_OUTPUT_WIDTH = 8,
    parameter int INPUT_STREAMS     = 1,
    parameter int OUTPUT_STREAMS    = 1

) (
    input i_clk,
    input i_rst,
    input [TASK_INPUT_WIDTH-1:0] i_data,
    input i_valid,
    input i_first,
    input i_last,
    output [TASK_OUTPUT_WIDTH-1:0] o_data,
    output o_valid,
    output o_last
);

  logic [TASK_OUTPUT_WIDTH-1:0] r_data; // Just a dummy register. Replace with your code.
  logic r_valid; // Just a dummy register. Replace with your code.
  logic r_last; // Just a dummy register. Replace with your code.

  always@(posedge i_clk) begin
    r_data <= i_data; // Just a dummy assignement. Replace with your code.
    r_valid <= i_valid; // Just a dummy assignement. Replace with your code.
    r_last <= i_last; // Just a dummy assignement. Replace with your code.
  end

  assign o_data = r_data; // Just a dummy assignement. Replace with your code.
  assign o_valid = r_valid; // Just a dummy assignement. Replace with your code.
  assign o_last = r_last; // Just a dummy assignement. Replace with your code.

endmodule
