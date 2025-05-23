
`timescale 1 ns / 1 ps

module reset_delay (
  input i_clk,
  input i_rstn,
  input i_enb,
  output o_q 
);

  reg [9:0] cnt;
  reg q;
  assign o_q = q;

  always@(posedge i_clk) begin
    if (i_rstn==1'b0)
      cnt <= 0;
    else if (i_enb==1'b1)
      cnt <= cnt + 1;
  end

  always@(posedge i_clk) begin
    if (i_rstn==1'b0)
      q <= 1'b0;
    else if (cnt == 10'b1111111111)
      q <= 1'b1;
  end

endmodule
