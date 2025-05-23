`timescale 1 ns / 1 ps
module task_7 #(
    parameter int TASK_INPUT_WIDTH  = 8,
    parameter int TASK_OUTPUT_WIDTH = 32,
    parameter int INPUT_STREAMS     = 9,
    parameter int OUTPUT_STREAMS    = 2
)(
    input i_clk,
    input i_rst,
    input i_valid,
    input i_last,
    input i_first,
    input [TASK_INPUT_WIDTH-1:0] i_data_A_0,
    input [TASK_INPUT_WIDTH-1:0] i_data_A_1,
    input [TASK_INPUT_WIDTH-1:0] i_data_A_2,
    input [TASK_INPUT_WIDTH-1:0] i_data_D_0,
    input [TASK_INPUT_WIDTH-1:0] i_data_D_1,
    input [TASK_INPUT_WIDTH-1:0] i_data_D_2,
    input [TASK_INPUT_WIDTH-1:0] i_data_B_0,
    input [TASK_INPUT_WIDTH-1:0] i_data_B_1,
    input [TASK_INPUT_WIDTH-1:0] i_data_B_2,
    output [TASK_OUTPUT_WIDTH-1:0] o_data_AB,
    output [TASK_OUTPUT_WIDTH-1:0] o_data_DB,
    output o_valid,
    output o_last
);
  
  
  logic [TASK_INPUT_WIDTH-1:0] i_data_A [3];
  logic [TASK_INPUT_WIDTH-1:0] i_data_D [3];
  logic [TASK_INPUT_WIDTH-1:0] i_data_B [3];

  assign i_data_A[0] = i_data_A_0;
  assign i_data_A[1] = i_data_A_1;
  assign i_data_A[2] = i_data_A_2;
  assign i_data_D[0] = i_data_D_0;
  assign i_data_D[1] = i_data_D_1;
  assign i_data_D[2] = i_data_D_2;
  assign i_data_B[0] = i_data_B_0;
  assign i_data_B[1] = i_data_B_1;
  assign i_data_B[2] = i_data_B_2;

  logic [TASK_OUTPUT_WIDTH-1:0] r_data_AB; // Just a dummy register. Replace with your code.
  logic [TASK_OUTPUT_WIDTH-1:0] r_data_DB; // Just a dummy register. Replace with your code.
  logic r_valid; // Just a dummy register. Replace with your code.
  logic r_last; // Just a dummy register. Replace with your code.
  
  always@(posedge i_clk) begin
    r_data_AB <= i_data_A[0]; // Just a dummy assignement. Replace with your code.
    r_data_DB <= i_data_A[1]; // Just a dummy assignement. Replace with your code.
    r_valid <= i_valid; // Just a dummy assignement. Replace with your code.
    r_last <= i_last; // Just a dummy assignement. Replace with your code.
  end

  assign o_data_AB = r_data_AB; // Just a dummy assignement. Replace with your code.
  assign o_data_DB = r_data_DB; // Just a dummy assignement. Replace with your code.
  assign o_valid = r_valid; // Just a dummy assignement. Replace with your code.
  assign o_last = r_last; // Just a dummy assignement. Replace with your code.

endmodule
