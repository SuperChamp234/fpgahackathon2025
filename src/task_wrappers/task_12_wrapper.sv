module task_12_wrapper #(
    parameter int TASK_INPUT_WIDTH = 8,
    parameter int TASK_OUTPUT_WIDTH = 8,
    parameter int INPUT_STREAMS = 8,
    parameter int OUTPUT_STREAMS = 8,
    parameter int MAX_SAMPLES_IN = 1000
) (
    input i_clk,
    input i_rst,
    input i_rst_data_width_converter,
    task_in_interface.slave tis,
    task_out_interface.slave tos,
    input tv_in_last
);

  localparam int TASK_OUTPUT_WIDTH_ADJUSTED = 32;
  localparam int MIN_FIFO_SIZE = 64;
  localparam int DESERIALIZER_FIFO_SIZE = 2 ** ($clog2(
      MAX_SAMPLES_IN / INPUT_STREAMS
  ) + 1);
  localparam int SERIALIZER_FIFO_SIZE = 2 ** ($clog2(
      MAX_SAMPLES_IN / INPUT_STREAMS
  ) + 1);

  localparam int DESERIALIZER_FIFO_SIZE_FINAL = (DESERIALIZER_FIFO_SIZE < MIN_FIFO_SIZE) ? MIN_FIFO_SIZE : DESERIALIZER_FIFO_SIZE;
  localparam int SERIALIZER_FIFO_SIZE_FINAL = (SERIALIZER_FIFO_SIZE < MIN_FIFO_SIZE) ? MIN_FIFO_SIZE : SERIALIZER_FIFO_SIZE;

  logic w_task_input_valid;
  logic w_task_input_first;
  logic w_task_input_last;
  logic [TASK_INPUT_WIDTH-1:0] w_task_input_data[INPUT_STREAMS];
  logic [TASK_OUTPUT_WIDTH-1:0] w_task_output_data[OUTPUT_STREAMS];
  logic w_task_output_valid;
  logic w_task_output_last;
  logic [TASK_OUTPUT_WIDTH-1:0] w_output_data;
  logic w_output_valid;
  logic w_output_last;
  logic [31:0] w_lat;
  logic o_tanswer_valid;
  logic [31:0] o_tanswer_data;
  logic [31:0] w_packet_size_in_bytes;
  logic o_tanswer_data_last;
    
  assign tos.task_answer_valid = o_tanswer_valid;
  assign tos.task_answer_data = o_tanswer_data;
  assign tos.task_answer_data_last = o_tanswer_data_last;
  assign tos.task_answer_size_in_bytes =  w_packet_size_in_bytes;
  assign tos.task_answer_latency = w_lat;

  generate
    if (INPUT_STREAMS == 1) begin : gen_if_no_deserializer
      assign w_task_input_data[0] = tis.task_data[TASK_INPUT_WIDTH-1:0];
      assign w_task_input_valid = tis.task_data_valid;
      assign w_task_input_first = tis.task_data_first;
      assign w_task_input_last = tis.task_data_last;
    end else begin : gen_if_deserializer
      task_deserializer #(
          .DATA_WIDTH(TASK_INPUT_WIDTH),
          .OUTPUT_STREAMS(INPUT_STREAMS),
          .FIFO_SIZE(DESERIALIZER_FIFO_SIZE_FINAL)
      ) task_12_deserializer (
          .i_clk  (i_clk),
          .i_rst  (i_rst),
          .i_data (tis.task_data[TASK_INPUT_WIDTH-1:0]),
          .i_last (tis.task_data_last),
          .i_first(tis.task_data_first),
          .i_valid(tis.task_data_valid),          
          .o_data (w_task_input_data),
          .o_valid(w_task_input_valid),
          .o_last (w_task_input_last),
          .o_first(w_task_input_first)
      );
    end
  endgenerate

  task_12 #(
      .TASK_INPUT_WIDTH(TASK_INPUT_WIDTH),
      .TASK_OUTPUT_WIDTH(TASK_OUTPUT_WIDTH),
      .INPUT_STREAMS(INPUT_STREAMS),
      .OUTPUT_STREAMS(OUTPUT_STREAMS)
  ) task_12 (
      .i_clk  (i_clk),
      .i_rst  (i_rst),
      .i_first(w_task_input_first),
      .i_last (w_task_input_last),
      .i_data (w_task_input_data[0]),
      .i_valid(w_task_input_valid),
      .o_data (w_task_output_data[0]),
      .o_valid(w_task_output_valid),
      .o_last (w_task_output_last)
  );
  
  bytes_counter #(
      .TASK_OUTPUT_WIDTH(TASK_OUTPUT_WIDTH),
      .OUTPUT_STREAMS(OUTPUT_STREAMS)
  ) bytes_counter(
    .i_clk(i_clk),
    .i_rst(i_rst || tv_in_last),
    .input_last(w_task_output_last),
    .input_valid(w_task_output_valid),
    .answer_size_in_bytes(w_packet_size_in_bytes)
  );


  task_latency_meas task_12_latency_meas (
      .i_clk(i_clk),
      .i_rst(i_rst),
      .i_in_valid(w_task_input_valid),
      .i_out_valid(w_task_output_valid),
      .i_get_ready(tv_in_last),
      .o_lat(w_lat)
  );

  generate
    if (OUTPUT_STREAMS == 1) begin : gen_if_no_serializer
      assign w_output_data = w_task_output_data[0];
      assign w_output_valid = w_task_output_valid;
      assign w_output_last  = w_task_output_last;
    end else begin : gen_if_serializer
      task_serializer #(
          .DATA_WIDTH(TASK_OUTPUT_WIDTH),
          .INPUT_STREAMS(OUTPUT_STREAMS),
          .FIFO_SIZE(SERIALIZER_FIFO_SIZE_FINAL)
      ) task_12_serializer (
          .i_clk(i_clk),
          .i_rst(i_rst),
          .i_data(w_task_output_data),
          .i_input_last(w_task_output_last),
          .i_valid(w_task_output_valid),
          .o_data(w_output_data),
          .o_valid(w_output_valid),
          .o_last(w_output_last)
      );
    end
  endgenerate
  
   axis_data_width_converter #(
    .S_TDATA_WIDTH(TASK_OUTPUT_WIDTH),
    .M_TDATA_WIDTH(TASK_OUTPUT_WIDTH_ADJUSTED)
  ) task_12_data_width_converter (
    .clk(i_clk),
    .rst(i_rst || i_rst_data_width_converter),
    .s_axis_tdata(w_output_data),
    .s_axis_tstrb({TASK_OUTPUT_WIDTH/8{1'b1}}),
    .s_axis_tvalid(w_output_valid),
    .s_axis_tready(),
    .s_axis_tlast(w_output_last),
    .s_axis_tfirst(),
    .m_axis_tdata(o_tanswer_data),
    .m_axis_tstrb(),
    .m_axis_tvalid(o_tanswer_valid),
    .m_axis_tready(1'b1),
    .m_axis_tlast(o_tanswer_data_last),
    .m_axis_tfirst()
  ); 

endmodule
