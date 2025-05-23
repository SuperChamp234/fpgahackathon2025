`timescale 1ns / 1ps

module task_deserializer #(
    parameter int DATA_WIDTH = 8,
    parameter int OUTPUT_STREAMS = 3,
    parameter int FIFO_SIZE = 1024
) (
    input i_clk,
    input i_rst,
    input [DATA_WIDTH-1:0] i_data,
    input i_last,
    input i_first,
    input i_valid,
    output [DATA_WIDTH-1:0] o_data[OUTPUT_STREAMS],
    output o_valid,
    output o_last,
    output o_first
);

  logic [OUTPUT_STREAMS-1:0] w_fifo_valid;
  logic w_fifo_valid_all;
  logic [OUTPUT_STREAMS-1:0] w_empty;
  logic w_rdreq;

  logic r_fifo_valid_all_del;
  logic [DATA_WIDTH-1:0] r_input_data;
  logic [OUTPUT_STREAMS-1:0] r_wrreq;
  logic [$clog2(OUTPUT_STREAMS):0] r_mux_counter;

  typedef enum {
    s_IDLE,
    s_LOAD,
    s_START_SEND,
    s_SEND
  } task_output_enum;
  task_output_enum state;
  task_output_enum next_state;

  //--------- NEXT STATE LOGIC  -----------------------------------------------
  always_comb begin
    if (i_rst) begin
      next_state = s_IDLE;
    end else begin
      case (state)
        s_IDLE: begin
          if (i_first) next_state = s_LOAD;
          else next_state = s_IDLE;
        end
        s_LOAD: begin
          if (i_last) next_state = s_START_SEND;
          else next_state = s_LOAD;
        end
        s_START_SEND: begin
          next_state = s_SEND;
        end
        s_SEND: begin
          if (&w_empty) next_state = s_IDLE;
          else next_state = s_SEND;
        end
        default: begin
          next_state = s_IDLE;
        end
      endcase
    end
  end
  //--------- UPDATING STATE    ----------------------------------------------
  always_ff @(posedge i_clk)
    if (i_rst) begin
      state <= s_IDLE;
    end else begin
      state <= next_state;
    end
  //--------- OUTPUT LOGIC      ----------------------------------------------
  always_ff @(posedge i_clk) begin
    if (state == s_LOAD) begin
      if (r_mux_counter >= (OUTPUT_STREAMS - 1)) r_mux_counter <= 0;
      else r_mux_counter <= r_mux_counter + 1'b1;
    end else r_mux_counter <= 0;
  end

  always_comb begin
    r_wrreq = '0;
    if (state == s_LOAD || state == s_START_SEND)
      r_wrreq[r_mux_counter] = 1'b1;
  end

  always_ff @(posedge i_clk) begin
    r_input_data <= i_data;
    r_fifo_valid_all_del <= w_fifo_valid_all;
  end

  assign w_rdreq = (state == s_SEND);
  assign w_fifo_valid_all = &w_fifo_valid;
  assign o_valid = &w_fifo_valid;
  assign o_first = (!r_fifo_valid_all_del && w_fifo_valid_all);
  assign o_last = (state == s_SEND && &w_empty);


  //--------- BUFFER FIFOS      -----------------------------------------------
  generate
    for (genvar i = 0; i < OUTPUT_STREAMS; i++) begin : gen_deserializer_fifo
      xpm_fifo_sync #(
        .CASCADE_HEIGHT(0),  // DECIMAL
        .DOUT_RESET_VALUE("0"),  // String
        .ECC_MODE("no_ecc"),  // String
        .FIFO_MEMORY_TYPE("distributed"),  // String
        //.FIFO_READ_LATENCY(0),     // DECIMAL
        .FIFO_READ_LATENCY(1),  // DECIMAL
        .FIFO_WRITE_DEPTH(FIFO_SIZE),  // DECIMAL
        .FULL_RESET_VALUE(0),  // DECIMAL
        .PROG_EMPTY_THRESH(3),  // DECIMAL
        .PROG_FULL_THRESH(),  // DECIMAL
        .RD_DATA_COUNT_WIDTH(1),  // DECIMAL
        .READ_DATA_WIDTH(DATA_WIDTH),  // DECIMAL
        //.READ_MODE("fwft"),         // String
        .READ_MODE("std"),  // String
        .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
        .USE_ADV_FEATURES("1802"),  // String
        .WAKEUP_TIME(0),  // DECIMAL
        .WRITE_DATA_WIDTH(DATA_WIDTH),  // DECIMAL
        .WR_DATA_COUNT_WIDTH(1)  // DECIMAL
      ) fifo_out (
        .almost_empty(), // 1-bit output: Almost Empty : When asserted, this signal indicates that
        // only one more read can be performed before the FIFO goes to empty.

        .almost_full(), // 1-bit output: Almost Full: When asserted, this signal indicates that
        // only one more write can be performed before the FIFO is full.

        .data_valid(w_fifo_valid[i]), // 1-bit output: Read Data Valid: When asserted, this signal indicates
        // that valid data is available on the output bus (dout).

        .dbiterr(), // 1-bit output: Double Bit Error: Indicates that the ECC decoder detected
        // a double-bit error and data in the FIFO core is corrupted.

        .dout(o_data[i]), // READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
        // when reading the FIFO.

        .empty(w_empty[i]), // 1-bit output: Empty Flag: When asserted, this signal indicates that the
        // FIFO is empty. Read requests are ignored when the FIFO is empty,
        // initiating a read while empty is not destructive to the FIFO.

        .full(), // 1-bit output: Full Flag: When asserted, this signal indicates that the
        // FIFO is full. Write requests are ignored when the FIFO is full,
        // initiating a write when the FIFO is full is not destructive to the
        // contents of the FIFO.

        .overflow(), // 1-bit output: Overflow: This signal indicates that a write request
        // (wren) during the prior clock cycle was rejected, because the FIFO is
        // full. Overflowing the FIFO is not destructive to the contents of the
        // FIFO.

        .prog_empty(), // 1-bit output: Programmable Empty: This signal is asserted when the
        // number of words in the FIFO is less than or equal to the programmable
        // empty threshold value. It is de-asserted when the number of words in
        // the FIFO exceeds the programmable empty threshold value.

        .prog_full(), // 1-bit output: Programmable Full: This signal is asserted when the
        // number of words in the FIFO is greater than or equal to the
        // programmable full threshold value. It is de-asserted when the number of
        // words in the FIFO is less than the programmable full threshold value.

        .rd_data_count(), // RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the
        // number of words read from the FIFO.

        .rd_rst_busy(), // 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read
        // domain is currently in a reset state.

        .sbiterr(), // 1-bit output: Single Bit Error: Indicates that the ECC decoder detected
        // and fixed a single-bit error.

        .underflow(), // 1-bit output: Underflow: Indicates that the read request (rd_en) during
        // the previous clock cycle was rejected because the FIFO is empty. Under
        // flowing the FIFO is not destructive to the FIFO.

        .wr_ack(), // 1-bit output: Write Acknowledge: This signal indicates that a write
        // request (wr_en) during the prior clock cycle is succeeded.

        .wr_data_count(), // WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
        // the number of words written into the FIFO.

        .wr_rst_busy(), // 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
        // write domain is currently in a reset state.

        .din(r_input_data), // WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
        // writing the FIFO.

        .injectdbiterr(1'b0), // 1-bit input: Double Bit Error Injection: Injects a double bit error if
        // the ECC feature is used on block RAMs or UltraRAM macros.

        .injectsbiterr(1'b0), // 1-bit input: Single Bit Error Injection: Injects a single bit error if
        // the ECC feature is used on block RAMs or UltraRAM macros.

        .rd_en(w_rdreq), // 1-bit input: Read Enable: If the FIFO is not empty, asserting this
        // signal causes data (on dout) to be read from the FIFO. Must be held
        // active-low when rd_rst_busy is active high.

        .rst(i_rst), // 1-bit input: Reset: Must be synchronous to wr_clk. The clock(s) can be
        // unstable at the time of applying reset, but reset must be released only
        // after the clock(s) is/are stable.

        .sleep(1'b0), // 1-bit input: Dynamic power saving- If sleep is High, the memory/fifo
        // block is in power saving mode.

        .wr_clk(i_clk), // 1-bit input: Write clock: Used for write operation. wr_clk must be a
        // free running clock.

        .wr_en(r_wrreq[i]) // 1-bit input: Write Enable: If the FIFO is not full, asserting this
        // signal causes data (on din) to be written to the FIFO Must be held
        // active-low when rst or wr_rst_busy or rd_rst_busy is active high

      );
    end
  endgenerate
endmodule
