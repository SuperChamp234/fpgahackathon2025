import tasks_parameters::*;
module task_in #(
  parameter int FIFO_DEPTH_IN_BYTES = 1024
) (
  input i_clk,
  input i_rst,
  input [31:0] current_task_number,
  input [31:0] num_valid_bytes_in_last_sample,
  input i_tdata_valid,
  input [31:0] i_tdata,
  input i_tdata_last,
  input i_output_last,
  output o_tready,
  output logic [31:0] o_data,
  output logic o_valid,
  output logic o_first,
  output logic o_last
);

  logic  w_empty;
  logic  [31:0] w_data_converted;
  logic  w_valid_converted;
  logic  w_first_converted;
  logic  w_last_converted;
  logic  [31:0] w_data;
  logic  w_valid;
  logic  w_first;
  logic  w_last;
  logic  [7:0] w_data_8;
  logic  w_valid_8;
  logic  w_first_8;
  logic  w_last_8;
  logic  [15:0] w_data_16;
  logic  w_valid_16;
  logic  w_first_16;
  logic  w_last_16;
  logic  r_tready;
  logic  r_first_flag;
  logic  r_valid_del;
  logic  fifo_flush; 
  logic  [1:0] cnt_8;
  logic  cnt_16;
  logic  w_read_from_fifo;
  logic  first_flag;

  typedef enum {
    s_INIT,
    s_IDLE,
    s_START_REQ,
    s_LOAD,
    s_SEND,
    s_FIFO_FLUSH
  } task_input_enum;
  task_input_enum state;
  task_input_enum next_state;

//--------- NEXT STATE LOGIC  ------------------------------------------------
  always @(*) begin
    if (i_rst) next_state = s_INIT;
    else begin
      case (state)
        s_INIT: begin
          next_state = s_START_REQ;
        end
        s_IDLE: begin
          if (w_empty && (r_first_flag || i_output_last))
            next_state = s_START_REQ;
          else if (!w_empty) next_state = s_SEND;
          else next_state = s_IDLE;
        end
        s_START_REQ: begin
          next_state = s_LOAD;
        end
        s_LOAD: begin
          if (i_tdata_last) next_state = s_IDLE;
          else next_state = s_LOAD;
        end
        s_SEND: begin
          if (w_empty) next_state = s_FIFO_FLUSH;
          else next_state = s_SEND;
        end
        s_FIFO_FLUSH: begin
          next_state = s_IDLE;
        end
        default: begin
          next_state = s_IDLE;
        end
      endcase
    end
  end
  //--------- UPDATING STATE    ----------------------------------------------
  always_ff @(posedge i_clk) begin
	  state <= next_state;
  end
  //--------- OUTPUT LOGIC      ----------------------------------------------
  always @(posedge i_clk) begin
    if ((state == s_START_REQ) || (state == s_LOAD && !i_tdata_last))
      r_tready <= 1'b1;
    else r_tready <= 1'b0;
  end

  assign o_tready = r_tready;
  
  always @(posedge i_clk) begin
    if(i_rst) begin
      cnt_8 <= 2'b00;
      cnt_16 <= 1'b0;
    end else if (state == s_SEND) begin
      cnt_8 <= cnt_8 + 1'b1;
      cnt_16 <= cnt_16 + 1'b1;
    end
  end
  
  

  always @(posedge i_clk) begin
    if (i_tdata_last) r_first_flag <= 0;
    else if (i_output_last) r_first_flag <= 1;
  end

  always @(posedge i_clk) begin
    if(state == s_IDLE)
      first_flag <= 1'b1;
    else if (state == s_SEND && w_valid)
      first_flag <= 1'b0;
  end
  
  always @(posedge i_clk) begin
    r_valid_del <= w_valid;
  end 
  
  assign w_first = (!r_valid_del && w_valid && first_flag);
  assign w_last  = (state == s_SEND && w_empty);

  always_ff @(posedge i_clk) begin
    if (state == s_FIFO_FLUSH)
      fifo_flush <= 1;
    else
      fifo_flush <= 0;
  end

  xpm_fifo_sync #(
    .CASCADE_HEIGHT(0),  // DECIMAL
    .DOUT_RESET_VALUE("0"),  // String
    .ECC_MODE("no_ecc"),  // String
    .FIFO_MEMORY_TYPE("ultra"),  // String
    .FIFO_READ_LATENCY(1),  // DECIMAL
    .FIFO_WRITE_DEPTH(FIFO_DEPTH_IN_BYTES),  // DECIMAL
    .FULL_RESET_VALUE(0),  // DECIMAL
    .PROG_EMPTY_THRESH(10),  // DECIMAL
    .PROG_FULL_THRESH(10),  // DECIMAL
    .RD_DATA_COUNT_WIDTH(1),  // DECIMAL
    .READ_DATA_WIDTH(32),  // DECIMAL
    .READ_MODE("std"),  // String
    .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .USE_ADV_FEATURES("1707"),  // String
    .WAKEUP_TIME(0),  // DECIMAL
    .WRITE_DATA_WIDTH(32),  // DECIMAL
    .WR_DATA_COUNT_WIDTH(1)  // DECIMAL
  ) fifo_in (
    .almost_empty(), // 1-bit output: Almost Empty : When asserted, this signal indicates that
    // only one more read can be performed before the FIFO goes to empty.

    .almost_full(), // 1-bit output: Almost Full: When asserted, this signal indicates that
    // only one more write can be performed before the FIFO is full.

    .data_valid(w_valid), // 1-bit output: Read Data Valid: When asserted, this signal indicates
    // that valid data is available on the output bus (dout).
    
    .dbiterr(), // 1-bit output: Double Bit Error: Indicates that the ECC decoder detected
    // a double-bit error and data in the FIFO core is corrupted.

    .dout(w_data), // READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
    // when reading the FIFO.

    .empty(w_empty), // 1-bit output: Empty Flag: When asserted, this signal indicates that the
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

    .din(i_tdata), // WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
    // writing the FIFO.

    .injectdbiterr(1'b0), // 1-bit input: Double Bit Error Injection: Injects a double bit error if
    // the ECC feature is used on block RAMs or UltraRAM macros.

    .injectsbiterr(1'b0), // 1-bit input: Single Bit Error Injection: Injects a single bit error if
    // the ECC feature is used on block RAMs or UltraRAM macros.

    .rd_en(w_read_from_fifo), // 1-bit input: Read Enable: If the FIFO is not empty, asserting this
    // signal causes data (on dout) to be read from the FIFO. Must be held
    // active-low when rd_rst_busy is active high.

    .rst(i_rst || fifo_flush), // 1-bit input: Reset: Must be synchronous to wr_clk. The clock(s) can be
    // unstable at the time of applying reset, but reset must be released only
    // after the clock(s) is/are stable.

    .sleep(1'b0), // 1-bit input: Dynamic power saving- If sleep is High, the memory/fifo
    // block is in power saving mode.

    .wr_clk(i_clk), // 1-bit input: Write clock: Used for write operation. wr_clk must be a
    // free running clock.

    .wr_en(i_tdata_valid) // 1-bit input: Write Enable: If the FIFO is not full, asserting this
    // signal causes data (on din) to be written to the FIFO Must be held
    // active-low when rst or wr_rst_busy or rd_rst_busy is active high
  );
  
  axis_data_width_converter #(
    .S_TDATA_WIDTH(32),
    .M_TDATA_WIDTH(16)
  ) axis_data_width_converter_16 (
    .clk(i_clk),
    .rst(i_rst),
    .s_axis_tdata(w_data),
    .s_axis_tstrb({32/8{1'b1}}),
    .s_axis_tvalid(w_valid),
    .s_axis_tready(),
    .s_axis_tlast(w_last),
    .s_axis_tfirst(w_first),
    .m_axis_tdata(w_data_16),
    .m_axis_tstrb(),
    .m_axis_tvalid(w_valid_16),
    .m_axis_tready(1'b1),
    .m_axis_tlast(w_last_16),
    .m_axis_tfirst(w_first_16)
  );
  
    axis_data_width_converter #(
    .S_TDATA_WIDTH(32),
    .M_TDATA_WIDTH(8)
  ) axis_data_width_converter_8 (
    .clk(i_clk),
    .rst(i_rst),
    .s_axis_tdata(w_data),
    .s_axis_tstrb({32/8{1'b1}}),
    .s_axis_tvalid(w_valid),
    .s_axis_tready(),
    .s_axis_tlast(w_last),
    .s_axis_tfirst(w_first),
    .m_axis_tdata(w_data_8),
    .m_axis_tstrb(),
    .m_axis_tvalid(w_valid_8),
    .m_axis_tready(1'b1),
    .m_axis_tlast(w_last_8),
    .m_axis_tfirst(w_first_8)
  );
  
  always_comb begin
    if (tasks_params_array[current_task_number].DATA_WIDTH_IN == 8) begin
      w_data_converted = w_data_8;
      w_valid_converted = w_valid_8;
      w_last_converted = w_last_8;
      w_first_converted = w_first_8;
      w_read_from_fifo = (cnt_8 == 0 && state == s_SEND) ? 1'b1: 1'b0;
    end else if(tasks_params_array[current_task_number].DATA_WIDTH_IN == 16) begin
      w_data_converted = w_data_16;
      w_valid_converted = w_valid_16;
      w_last_converted = w_last_16;
      w_first_converted = w_first_16;
      w_read_from_fifo = (cnt_16 == 0 && state == s_SEND) ? 1'b1: 1'b0;
    end else if (tasks_params_array[current_task_number].DATA_WIDTH_IN == 32) begin
      w_data_converted = w_data;
      w_valid_converted = w_valid;
      w_last_converted = w_last;
      w_first_converted = w_first;
      w_read_from_fifo = (state == s_SEND) ? 1'b1: 1'b0;
    end else begin
      w_data_converted = {32{1'b0}};
      w_valid_converted = 1'b0;
      w_last_converted = 1'b0;
      w_first_converted = 1'b0;
      w_read_from_fifo = 1'b0;
    end
  end
  
  task_in_mask task_in_mask(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_set(state == s_START_REQ),
    .i_data(w_data_converted),
    .i_valid(w_valid_converted),
    .i_last(w_last),
    .i_last_2(w_last_converted),
    .i_first(w_first_converted),
    .is_input_16_bit(tasks_params_array[current_task_number].DATA_WIDTH_IN == 16),
    .num_valid_bytes_in_last_sample(num_valid_bytes_in_last_sample),
    .o_data(o_data),
    .o_valid(o_valid),
    .o_last(o_last),
    .o_first(o_first)
  );


endmodule
