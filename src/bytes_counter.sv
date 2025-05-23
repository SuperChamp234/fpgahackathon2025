`timescale 1ns / 1ps
module bytes_counter #(
    parameter int TASK_OUTPUT_WIDTH = 32,
    parameter int OUTPUT_STREAMS = 1
)(
    input                          i_clk,
    input                          i_rst,
    input                          input_valid,
    input                          input_last,
    output [31:0]                  answer_size_in_bytes
);

  localparam BYTES_IN_TASK_OUTPUT = TASK_OUTPUT_WIDTH/8;

  reg [31:0] answer_size_in_bytes_reg;
  reg input_last_detected;

  always@(posedge i_clk) begin
    if(i_rst)
      input_last_detected <= 1'b0;
    else
      input_last_detected <= input_last && input_valid;
  end

  always@(posedge i_clk) begin
    if(i_rst)
      answer_size_in_bytes_reg <= '0;
    else if(input_valid && !input_last_detected)
      answer_size_in_bytes_reg <= answer_size_in_bytes_reg + BYTES_IN_TASK_OUTPUT*OUTPUT_STREAMS;
  end
  
  assign answer_size_in_bytes = answer_size_in_bytes_reg;
  
endmodule

