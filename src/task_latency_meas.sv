module task_latency_meas (
  input i_clk,
  input i_rst,
  input i_in_valid,
  input i_out_valid,
  input i_get_ready,
  output [31:0] o_lat
);
  logic [31:0] r_lat;
  logic r_flag;

  always_ff @(posedge i_clk) begin
    if (i_rst || i_get_ready) begin
      r_lat  <= '0;
      r_flag <= 1'b0;
    end else begin
      if (i_in_valid) r_flag <= 1'b1;
      if (i_out_valid) r_flag <= 1'b0;
      if (r_flag && r_lat != {32{1'b1}}) r_lat <= r_lat + 1'b1;
    end
  end

  assign o_lat = r_lat;

endmodule
