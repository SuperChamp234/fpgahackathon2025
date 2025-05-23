`timescale 1ns / 1ps
`define ZYNQ_VIP_0 tb_top.mpsoc_sys.design_1_i.zynq_ultra_ps_e_0.inst
import tasks_parameters::*;
module tb_top;

// SET YOUR TASK HERE!
`define TASK_1
//`define TASK_2
//`define TASK_3
//`define TASK_4
//`define TASK_5
//`define TASK_6
//`define TASK_7
//`define TASK_8
//`define TASK_9
//`define TASK_10
//`define TASK_11
//`define TASK_12
//`define TASK_13
//`define TASK_14

// SET NUMBER OF INPUT AND OUTPUT SAMPLES FOR SIMULATION
`ifdef TASK_1
    localparam NUM_SAMPLES_IN  = 16;
    localparam NUM_SAMPLES_OUT = 1;
`elsif TASK_2
    localparam NUM_SAMPLES_IN  = 14;
    localparam NUM_SAMPLES_OUT = 12;
`elsif TASK_3
    localparam NUM_SAMPLES_IN = 16;
    localparam NUM_SAMPLES_OUT = 7;
`elsif TASK_4
    localparam NUM_SAMPLES_IN  = 8;
    localparam NUM_SAMPLES_OUT = 8;
`elsif TASK_5
    localparam NUM_SAMPLES_IN  = 40;
    localparam NUM_SAMPLES_OUT = 52;
`elsif TASK_6
    localparam NUM_SAMPLES_IN  = 514;
    localparam NUM_SAMPLES_OUT = 274;
`elsif TASK_7
    localparam NUM_SAMPLES_IN  = 72;
    localparam NUM_SAMPLES_OUT = 16;
`elsif TASK_8
    localparam NUM_SAMPLES_IN  = 6;
    localparam NUM_SAMPLES_OUT = 5;
`elsif TASK_9
    localparam NUM_SAMPLES_IN  = 3;
    localparam NUM_SAMPLES_OUT = 2;
`elsif TASK_10
    localparam NUM_SAMPLES_IN  = 128;
    localparam NUM_SAMPLES_OUT = 128;
`elsif TASK_11
    localparam NUM_SAMPLES_IN  = 64;
    localparam NUM_SAMPLES_OUT = 64;
`elsif TASK_12
    localparam NUM_SAMPLES_IN  = 16;
    localparam NUM_SAMPLES_OUT = 11;
`elsif TASK_13
    localparam NUM_SAMPLES_IN  = 566;
    localparam NUM_SAMPLES_OUT = 6;
`elsif TASK_14
    localparam NUM_SAMPLES_IN  = 3072;
    localparam NUM_SAMPLES_OUT = 3072;
`endif

`include "tb_defs.sv";

localparam NUM_32_BIT_SAMPLES_IN = ceil_div(NUM_SAMPLES_IN, 32/DATA_WIDTH_IN);
localparam NUM_SAMPLES_WITHIN_32_BIT = 32/DATA_WIDTH_OUT;

reg resp;
reg [31:0] readdata;
reg [DATA_WIDTH_OUT-1:0] readdata_adjusted;
reg [31:0] num_bytes_from_task;
reg [31:0] task_in [NUM_SAMPLES_IN];
reg [DATA_WIDTH_OUT-1:0] task_ref [NUM_SAMPLES_OUT];
reg [DATA_WIDTH_OUT-1:0] task_out [NUM_SAMPLES_OUT];

int err_count                  = 0;
int k                          = 0;
int num_32_bit_samples_to_read = 0;
int padding_bytes              = 0;
int num_bytes_to_read          = 0;
int num_samples_in_last_32_bit = 0;
int exp_num_of_bytes_in_answer = 0;

localparam logic [31:0] SMEM_BASEADDR       = 32'hA000_0000;
localparam logic [31:0] TASK_IN_OFFSET      = SMEM_BASEADDR;
localparam logic [31:0] TASK_OUT_OFFSET     = SMEM_BASEADDR + 32'h2000;
localparam logic [31:0] TV_IN_READY         = SMEM_BASEADDR + 32'h1_000C;
localparam logic [31:0] PL_READY            = SMEM_BASEADDR + 32'h1_0000;
localparam logic [31:0] TV_OUT_READY        = SMEM_BASEADDR + 32'h1_0010;
localparam logic [31:0] ENABLED_TASKS       = SMEM_BASEADDR + 32'h1_0004;
localparam logic [31:0] CURRENT_TASK        = SMEM_BASEADDR + 32'h1_0008;
localparam logic [31:0] NUM_BYTES_TO_TASK   = SMEM_BASEADDR + 32'h1_0018;
localparam logic [31:0] NUM_BYTES_FROM_TASK = SMEM_BASEADDR + 32'h1_001C;
localparam logic [31:0] TV_OUT_RCV_ACK      = SMEM_BASEADDR + 32'h1_0020;

initial
begin
    $display ("STARTING TB...");
    `ZYNQ_VIP_0.M_AXI_HPM0_FPD.master.IF.clr_xilinx_reset_check();
    check_max_words_in();
    $readmemh( $sformatf("task%0d.mem", TASK_NUMBER), task_in);
  `ifndef TASK_10
    $readmemh( $sformatf("task%0d_ref.mem", TASK_NUMBER), task_ref);
  `endif

    reset_soc();
    setup_soc();

    #2000ns;

    $display("\n******** First iteration ********\n");
    test_task();
    $display("\n******** Second iteration ********\n");
    test_task();
    $display("\n******** Third iteration ********\n");
    test_task();

///////////////// display results //////////////

    $display("---------------------------------------------");
    $display("----          TESTBENCH RESULTS          ----");
    $display("---------------------------------------------");

    if (err_count > 0) begin
        $display("      TEST FAILED!");
        $display("      NUMBER OF MISMATCHES: %d", err_count);
    end else
        $display("      TEST PASSED!");

    #10us $display("      Testbench finished");
    $finish;
end

    design_1_wrapper mpsoc_sys();

`ifdef TASK_10
function void check_sample(input reg [DATA_WIDTH_OUT-1:0] task_out_i, input reg [DATA_WIDTH_IN-1:0] task_in_j, input int i);
    static real pi = $acos(-1);
    real out_val, x_val, ref_val, diff;
    logic unsigned [23:0] temp_x;
    logic signed [24:0] temp_out;

    // CHANGE THRESHOLD HERE
    static real THRESHOLD = 0.0000075;

    temp_x = task_in_j[23:0];
    x_val = real'(temp_x) / (2.0 ** 23);
    ref_val =  $sin(2.0 * x_val - pi / 4.0);  // sin(2x - π/4);
    temp_out = task_out_i[24:0];
    out_val = real'(temp_out) / (2.0 ** 23);

    if(out_val > ref_val)
        diff = out_val - ref_val;
    else
        diff = ref_val - out_val;

    if(diff < THRESHOLD) begin
        $display("      TASK_OUT[%0d]:  %.8f | TASK_REF[%0d]:  %.8f | OK!", i, out_val, i, ref_val);
    end else begin
        $display("      TASK_OUT[%0d]:  %.8f | TASK_REF[%0d]:  %.8f | MISMATCH!", i, out_val, i, ref_val);
        err_count++;
    end
    $display("Difference: %.8f", diff);
endfunction
`else
function void check_sample(input reg [DATA_WIDTH_OUT-1:0] task_out_i, input reg [DATA_WIDTH_OUT-1:0] task_ref_j, input int i);
    if(task_out_i === task_ref_j)
        $display("      TASK_OUT[%0d]: 0x%0h | TASK_REF[%0d]: 0x%0h | OK!", i, task_out_i, i, task_ref_j);
    else begin
        $display("      TASK_OUT[%0d]: 0x%0h | TASK_REF[%0d]: 0x%0h | MISMATCH!", i, task_out_i, i, task_ref_j);
        err_count++;
    end
endfunction
`endif

function void check_max_words_in();
  if (NUM_SAMPLES_IN > MAX_SAMPLES_IN)
    $fatal(1, "NUM_SAMPLES_IN is bigger than MAX_SAMPLES_IN parameter declared for this task in task_parameters.svh!");
endfunction

function int ceil_div(input int x, input int y);
    if (y == 0) begin
        $fatal(1, "Division by zero error");
    end
    return (x % y == 0) ? (x / y) : (x / y + 1);
endfunction

function void round_x_to_mult_y(input int x, input int y, output int z, output int rounded_x);
  z = x % y;
  if (z == 0)
    rounded_x = x;
  else
    rounded_x = x + (y - z);
  z = y-z;
  if (z==4) z = 0; //TODO
endfunction

task wait_for_pl_ready();
    while(1) begin
        `ZYNQ_VIP_0.read_data(PL_READY, 4, readdata, resp);
        if (resp != 0 || readdata != 1)
            continue;
        else
            break;
    end
endtask

task write_tv_in_to_smem();
    for (int i=0; i<NUM_32_BIT_SAMPLES_IN; i++) begin
        `ZYNQ_VIP_0.write_data(TASK_IN_OFFSET+4*i, 4, task_in[i], resp);
    end
endtask

task wait_for_tv_out_ready();
    while(1) begin
        `ZYNQ_VIP_0.read_data(TV_OUT_READY, 4, readdata, resp);
        if (resp != 0 || readdata != 1)
            continue;
        else
            break;
    end
endtask

task reset_soc();
    `ZYNQ_VIP_0.por_srstb_reset(1'b1);
    #200;
    `ZYNQ_VIP_0.por_srstb_reset(1'b0);
    `ZYNQ_VIP_0.fpga_soft_reset(4'hf);
    #16;  // minimum 16 clock cycles.
    `ZYNQ_VIP_0.por_srstb_reset(1'b1);
    `ZYNQ_VIP_0.fpga_soft_reset(4'h0);
endtask

task setup_soc();
    // Set debug level info to off. For more info, set to 1.
    `ZYNQ_VIP_0.set_debug_level_info(0);
    `ZYNQ_VIP_0.set_channel_level_info("M_AXI_HPM0_FPD", 0);
    `ZYNQ_VIP_0.set_function_level_info("M_AXI_HPM0_FPD", 0);
    `ZYNQ_VIP_0.M_AXI_HPM0_FPD.master.IF.set_xilinx_reset_check_to_warn();
    `ZYNQ_VIP_0.set_stop_on_error(1);
    // Set minimum port verbosity. Change to 32'd400 for maximum.
    `ZYNQ_VIP_0.M_AXI_HPM0_FPD.set_verbosity(32'd0);
endtask

task read_data_from_smem();
    for (int i=0; i<num_32_bit_samples_to_read; i++) begin
        `ZYNQ_VIP_0.read_data(TASK_OUT_OFFSET+4*i, 4, readdata, resp);
        if(i == num_32_bit_samples_to_read-1) begin
          $display("\n      TASK LATENCY: %0d clock cycles", readdata);
        end else if (i == num_32_bit_samples_to_read-2) begin
          for(int j=0; j<num_samples_in_last_32_bit; j++) begin
            readdata_adjusted = readdata >> DATA_WIDTH_OUT*j;
            $display("      OUTPUT SAMPLE [%0d], 0x%0h", k, readdata_adjusted);
            task_out[k] = readdata_adjusted;
            k++;
          end
        end else begin
          for(int j=0; j<NUM_SAMPLES_WITHIN_32_BIT; j++) begin
            readdata_adjusted = readdata >> DATA_WIDTH_OUT*j;
            $display("      OUTPUT SAMPLE [%0d], 0x%0h", k, readdata_adjusted);
            task_out[k] = readdata_adjusted;
            k++;
          end
        end
    end
endtask

task set_reg_num_bytes_to_task();
    `ZYNQ_VIP_0.write_data(NUM_BYTES_TO_TASK, 4, NUM_SAMPLES_IN*(DATA_WIDTH_IN/8), resp);
endtask

task set_reg_current_task_number();
    `ZYNQ_VIP_0.write_data(CURRENT_TASK, 4, TASK_NUMBER, resp);
endtask

task set_reg_tv_in_ready();
    `ZYNQ_VIP_0.write_data(TV_IN_READY, 4, 32'h0000_0001, resp);
endtask

task read_reg_num_bytes_from_task();
    `ZYNQ_VIP_0.read_data(NUM_BYTES_FROM_TASK, 4, num_bytes_from_task, resp);
    $display("      NUM_BYTES_FROM_TASK: %0d", num_bytes_from_task);
    exp_num_of_bytes_in_answer = DATA_WIDTH_OUT*NUM_SAMPLES_OUT/8;
    if (exp_num_of_bytes_in_answer === num_bytes_from_task)
        $display("      NUMBER OF BYTES FROM TASK CORRECT");
    else begin
        $display("      NUMBER OF BYTES FROM TASK INCORRECT: EXPECTED: %d ACTUAL: %d", exp_num_of_bytes_in_answer, num_bytes_from_task);
        err_count++;
    end
endtask

task set_tv_out_rcv_ack_reg();
    `ZYNQ_VIP_0.write_data(TV_OUT_RCV_ACK, 4, 32'h1, resp);
endtask

task calc_number_of_samples();
    round_x_to_mult_y(num_bytes_from_task, 4, padding_bytes, num_bytes_to_read);
    num_bytes_to_read += 4;
    num_32_bit_samples_to_read = num_bytes_to_read/4;
    num_samples_in_last_32_bit = NUM_SAMPLES_WITHIN_32_BIT  - (padding_bytes * 8/DATA_WIDTH_OUT);
endtask

task compare_task_out_with_task_ref();
    for(int i=0; i<NUM_SAMPLES_OUT; i++) begin
  `ifdef TASK_10
        check_sample(task_out[i], task_in[i], i);
  `else
        check_sample(task_out[i], task_ref[i], i);
  `endif
    end
endtask

task test_task();
    task_out = '{default:'bx};
    k = 0;
    wait_for_pl_ready();
    write_tv_in_to_smem();
    set_reg_num_bytes_to_task();
    set_reg_current_task_number();
    set_reg_tv_in_ready();
    wait_for_tv_out_ready();
    read_reg_num_bytes_from_task();
    calc_number_of_samples();
    read_data_from_smem();
    compare_task_out_with_task_ref();
    set_tv_out_rcv_ack_reg();
endtask

endmodule
