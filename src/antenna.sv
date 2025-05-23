// Hackathon 2025
`timescale 1 ns / 1 ps
module antenna
#(
  parameter DATA_WIDTH = 16,
  parameter DLY_NUM    = 3
)(
  input                  clk,
  input                  reset,

  input                  tvalid,
  input [DATA_WIDTH-1:0] tdata,

  input                  ping,
  output logic           pong,
  output logic           ping_ready
);

  localparam DLY_PTR_WIDTH = $clog2(DLY_NUM);
  localparam PING_RDY_DELAY = 1000;

  logic [DATA_WIDTH-1:0]    delay_tab [DLY_NUM];
  logic [DLY_PTR_WIDTH-1:0] dly_ptr_wr;
  logic [DLY_PTR_WIDTH-1:0] dly_ptr_rd;
  logic [DATA_WIDTH-1:0]    dly_cnt;
  logic [DATA_WIDTH-1:0]    ping_rdy_cnt;
  logic ping_ready_r;
  logic first_ping_rdy;
  logic done;

  assign ping_ready = ping_ready_r;

  always_ff @(posedge clk) begin
    if (tvalid) begin
      delay_tab[dly_ptr_wr] <= tdata;
      if (dly_ptr_wr < DLY_NUM-1)
        dly_ptr_wr <= dly_ptr_wr + 1'd1;
      else
        dly_ptr_wr <= '0;
    end

    if (reset)
      dly_ptr_wr <= '0;
  end


  always_ff @(posedge clk) begin
    pong <= 1'b0;

    if (ping && ping_ready_r) begin
      dly_cnt <= delay_tab[dly_ptr_rd] - 1'd1;
      if (dly_ptr_rd < DLY_NUM-1)
        dly_ptr_rd <= dly_ptr_rd + 1'd1;
      else begin
        dly_ptr_rd <= '0;
        done <= 1'b1;
      end
    end

    if (dly_cnt > 0)
      dly_cnt <= dly_cnt - 1'd1;

    if (dly_cnt == 1)
      pong <= 1'b1;

    if (tvalid && done)
      done <= 1'b0;

    if (reset) begin
      dly_ptr_rd <= '0;
      dly_cnt <= '0;
      done <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (first_ping_rdy && (dly_ptr_wr == 2))
      ping_rdy_cnt <= PING_RDY_DELAY;

    if (ping && ping_ready_r) begin
      ping_ready_r <= 1'b0;
      ping_rdy_cnt <= delay_tab[dly_ptr_rd] + PING_RDY_DELAY;
    end

    if (ping_rdy_cnt > 0)
      ping_rdy_cnt <= ping_rdy_cnt - 1'd1;

    if (ping_rdy_cnt == 1) begin
      ping_ready_r   <= 1'b1;
      first_ping_rdy <= 1'b0;
    end

    if (done==1'b1) begin
      ping_ready_r   <= 1'b0;
      first_ping_rdy <= 1'b1;
    end

    if (reset) begin
      ping_ready_r   <= 1'b0;
      ping_rdy_cnt   <= '0;
      first_ping_rdy <= 1'b1;
    end
  end

endmodule
