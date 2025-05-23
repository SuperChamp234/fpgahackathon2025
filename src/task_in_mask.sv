module task_in_mask(
  input i_clk,
  input i_rst,
  input i_set,
  input [31:0] i_data,
  input i_valid,
  input i_last,
  input i_last_2,
  input i_first,
  input is_input_16_bit,
  input [31:0] num_valid_bytes_in_last_sample,
  output logic [31:0] o_data,
  output logic o_valid,
  output logic o_last,
  output logic o_first
);

  logic [2:0] cnt;
  logic cnt_run;
  logic last_detected;
  logic [31:0] r_data_del [2];
  logic r_valid_del [2];
  logic r_first_del [2];
  logic r_last;
  logic [31:0] num_valid_last_samples;
  
  logic [31:0] w_data;
  logic w_valid;
  logic w_last;
  logic w_first;
  
  always@(posedge i_clk) begin
    r_data_del[0] <= i_data;
    r_data_del[1] <= r_data_del[0];
    r_valid_del[0] <= i_valid;
    r_valid_del[1] <= r_valid_del[0];
    r_first_del[0] <= i_first;
    r_first_del[1] <= r_first_del[0];   
  end
  
  assign num_valid_last_samples = (is_input_16_bit) ? num_valid_bytes_in_last_sample >> 1 : num_valid_bytes_in_last_sample;
  
  assign w_data = (num_valid_bytes_in_last_sample == 4) ? i_data : r_data_del[1];
  assign w_valid = (num_valid_bytes_in_last_sample == 4) ? i_valid : r_valid_del[1];
  assign w_last = (num_valid_bytes_in_last_sample == 4) ? i_last_2 : r_last;
  assign w_first = (num_valid_bytes_in_last_sample == 4) ? i_first : r_first_del[1];
  
  assign o_data = (!last_detected) ? w_data : {32{1'b0}};
  assign o_valid = (!last_detected) ? w_valid : 1'b0;
  assign o_last = (!last_detected) ? w_last : 1'b0;
  assign o_first = (!last_detected) ? w_first : 1'b0;

  always@(posedge i_clk) begin
    if(i_rst || i_set) begin
      cnt <= 0;
      cnt_run <= 1'b0;
      last_detected <= 1'b0;
    end else if(i_last) begin
      cnt_run <= 1'b1;
    end
    
    if(cnt_run)
      cnt <= cnt + 1'b1;

    if(cnt == num_valid_last_samples && num_valid_last_samples > 0) begin
      cnt <= 0;
      cnt_run <= 1'b0;
      r_last <= 1'b1;
    end else
      r_last <= 1'b0;
      
    if(r_last)
      last_detected <= 1'b1;
    
  end

endmodule
