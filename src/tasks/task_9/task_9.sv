`timescale 1ns / 1ps
module task_9 #(
    parameter int TASK_OUTPUT_WIDTH = 32
) (
    input i_clk,
    input i_rst,

    input  ping_ready,
    output logic ping,
    input  pong,

    output [TASK_OUTPUT_WIDTH-1:0] o_data,
    output o_valid,
    output o_last
);

  localparam int DELAY = 10;
  logic [15:0] dummy_cnt;
  logic dummy_bit;
  logic last, valid;

  assign o_last = last;
  assign o_valid = valid;
  assign o_data = 32'hdeadbeef;

  always_ff @(posedge i_clk) begin
    if (dummy_cnt > 0)
      dummy_cnt <= dummy_cnt - 1;
    else begin
      dummy_cnt <= 16'hffff;
      dummy_bit <= ~dummy_bit;
    end

    if (i_rst) begin
      dummy_cnt <= 16'hffff;
      dummy_bit <= 1'b0;
    end
  end

  always_ff @(posedge i_clk) begin
    if (dummy_cnt == 0) begin
      valid <= 1'b1;
      last  <= dummy_bit;
    end else begin
      valid <= 1'b0;
      last <= 1'b0;
    end
  end

  always_ff @(posedge i_clk) begin
    if(ping_ready)
      ping <= 1'b1;
    else
      ping <= 1'b0;
  end


endmodule
