package tasks_parameters;

  localparam NUMBER_OF_TASKS = 14;
  // TASK 1
  localparam TASK_1_DATA_WIDTH_IN = 16;
  localparam TASK_1_DATA_WIDTH_OUT = 16;
  localparam TASK_1_INPUT_STREAMS = 1;
  localparam TASK_1_OUTPUT_STREAMS = 1;
  localparam TASK_1_MAX_SAMPLES_IN = 4096;
  // TASK 2
  localparam TASK_2_DATA_WIDTH_IN = 8;
  localparam TASK_2_DATA_WIDTH_OUT = 8;
  localparam TASK_2_INPUT_STREAMS = 1;
  localparam TASK_2_OUTPUT_STREAMS = 1;
  localparam TASK_2_MAX_SAMPLES_IN = 4096;
  // TASK 3
  localparam TASK_3_DATA_WIDTH_IN  = 8;
  localparam TASK_3_DATA_WIDTH_OUT = 8;
  localparam TASK_3_INPUT_STREAMS  = 1;
  localparam TASK_3_OUTPUT_STREAMS = 1;
  localparam TASK_3_MAX_SAMPLES_IN = 33;
  // TASK 4
  localparam TASK_4_DATA_WIDTH_IN = 16;
  localparam TASK_4_DATA_WIDTH_OUT = 16;
  localparam TASK_4_INPUT_STREAMS = 1;
  localparam TASK_4_OUTPUT_STREAMS = 1;
  localparam TASK_4_MAX_SAMPLES_IN = 4096;
  // TASK 5
  localparam TASK_5_DATA_WIDTH_IN = 8;
  localparam TASK_5_DATA_WIDTH_OUT = 16;
  localparam TASK_5_INPUT_STREAMS = 1;
  localparam TASK_5_OUTPUT_STREAMS = 1;
  localparam TASK_5_MAX_SAMPLES_IN = 4096;
  // TASK 6
  localparam TASK_6_DATA_WIDTH_IN = 8;
  localparam TASK_6_DATA_WIDTH_OUT = 8;
  localparam TASK_6_INPUT_STREAMS = 1;
  localparam TASK_6_OUTPUT_STREAMS = 1;
  localparam TASK_6_MAX_SAMPLES_IN = 2048;
  // TASK 7
  localparam TASK_7_DATA_WIDTH_IN = 8;
  localparam TASK_7_DATA_WIDTH_OUT = 32;
  localparam TASK_7_INPUT_STREAMS = 9;
  localparam TASK_7_OUTPUT_STREAMS = 2;
  localparam TASK_7_MAX_SAMPLES_IN = 4096;
  // TASK 8
  localparam TASK_8_DATA_WIDTH_IN = 8;
  localparam TASK_8_DATA_WIDTH_OUT = 8;
  localparam TASK_8_INPUT_STREAMS = 1;
  localparam TASK_8_OUTPUT_STREAMS = 1;
  localparam TASK_8_MAX_SAMPLES_IN = 8192;
  // TASK 9
  localparam TASK_9_DATA_WIDTH_IN = 16;
  localparam TASK_9_DATA_WIDTH_OUT = 32;
  localparam TASK_9_INPUT_STREAMS = 1;
  localparam TASK_9_OUTPUT_STREAMS = 1;
  localparam TASK_9_MAX_SAMPLES_IN = 128;
  // TASK 10
  localparam TASK_10_DATA_WIDTH_IN = 32;
  localparam TASK_10_DATA_WIDTH_OUT = 32;
  localparam TASK_10_INPUT_STREAMS = 1;
  localparam TASK_10_OUTPUT_STREAMS = 1;
  localparam TASK_10_MAX_SAMPLES_IN = 1024;
  // TASK 11
  localparam TASK_11_DATA_WIDTH_IN = 8;
  localparam TASK_11_DATA_WIDTH_OUT = 8;
  localparam TASK_11_INPUT_STREAMS = 1;
  localparam TASK_11_OUTPUT_STREAMS = 1;
  localparam TASK_11_MAX_SAMPLES_IN = 4096;
  // TASK 12
  localparam TASK_12_DATA_WIDTH_IN = 8;
  localparam TASK_12_DATA_WIDTH_OUT = 8;
  localparam TASK_12_INPUT_STREAMS = 1;
  localparam TASK_12_OUTPUT_STREAMS = 1;
  localparam TASK_12_MAX_SAMPLES_IN = 8192;
  // TASK 13
  localparam TASK_13_DATA_WIDTH_IN = 16;
  localparam TASK_13_DATA_WIDTH_OUT = 16;
  localparam TASK_13_INPUT_STREAMS = 1;
  localparam TASK_13_OUTPUT_STREAMS = 1;
  localparam TASK_13_MAX_SAMPLES_IN = 4096;
  // TASK 14
  localparam TASK_14_DATA_WIDTH_IN = 8;
  localparam TASK_14_DATA_WIDTH_OUT = 8;
  localparam TASK_14_INPUT_STREAMS = 1;
  localparam TASK_14_OUTPUT_STREAMS = 1;
  localparam TASK_14_MAX_SAMPLES_IN = 3072;

  typedef struct packed {
    int DATA_WIDTH_IN;
    int DATA_WIDTH_OUT;
    int INPUT_STREAMS;
    int OUTPUT_STREAMS;
    int MAX_SAMPLES_IN;
  } tasks_params;

  tasks_params [1:NUMBER_OF_TASKS] tasks_params_array = '{
      '{
          TASK_1_DATA_WIDTH_IN,
          TASK_1_DATA_WIDTH_OUT,
          TASK_1_INPUT_STREAMS,
          TASK_1_OUTPUT_STREAMS,
          TASK_1_MAX_SAMPLES_IN
      },
      '{
          TASK_2_DATA_WIDTH_IN,
          TASK_2_DATA_WIDTH_OUT,
          TASK_2_INPUT_STREAMS,
          TASK_2_OUTPUT_STREAMS,
          TASK_2_MAX_SAMPLES_IN
      },
      '{
          TASK_3_DATA_WIDTH_IN,
          TASK_3_DATA_WIDTH_OUT,
          TASK_3_INPUT_STREAMS,
          TASK_3_OUTPUT_STREAMS,
          TASK_3_MAX_SAMPLES_IN
      },
      '{
          TASK_4_DATA_WIDTH_IN,
          TASK_4_DATA_WIDTH_OUT,
          TASK_4_INPUT_STREAMS,
          TASK_4_OUTPUT_STREAMS,
          TASK_4_MAX_SAMPLES_IN
      },
      '{
          TASK_5_DATA_WIDTH_IN,
          TASK_5_DATA_WIDTH_OUT,
          TASK_5_INPUT_STREAMS,
          TASK_5_OUTPUT_STREAMS,
          TASK_5_MAX_SAMPLES_IN
      },
      '{
          TASK_6_DATA_WIDTH_IN,
          TASK_6_DATA_WIDTH_OUT,
          TASK_6_INPUT_STREAMS,
          TASK_6_OUTPUT_STREAMS,
          TASK_6_MAX_SAMPLES_IN
      },
      '{
          TASK_7_DATA_WIDTH_IN,
          TASK_7_DATA_WIDTH_OUT,
          TASK_7_INPUT_STREAMS,
          TASK_7_OUTPUT_STREAMS,
          TASK_7_MAX_SAMPLES_IN
      },
      '{
          TASK_8_DATA_WIDTH_IN,
          TASK_8_DATA_WIDTH_OUT,
          TASK_8_INPUT_STREAMS,
          TASK_8_OUTPUT_STREAMS,
          TASK_8_MAX_SAMPLES_IN
      },
      '{
          TASK_9_DATA_WIDTH_IN,
          TASK_9_DATA_WIDTH_OUT,
          TASK_9_INPUT_STREAMS,
          TASK_9_OUTPUT_STREAMS,
          TASK_9_MAX_SAMPLES_IN
      },
      '{
          TASK_10_DATA_WIDTH_IN,
          TASK_10_DATA_WIDTH_OUT,
          TASK_10_INPUT_STREAMS,
          TASK_10_OUTPUT_STREAMS,
          TASK_10_MAX_SAMPLES_IN
      },
      '{
          TASK_11_DATA_WIDTH_IN,
          TASK_11_DATA_WIDTH_OUT,
          TASK_11_INPUT_STREAMS,
          TASK_11_OUTPUT_STREAMS,
          TASK_11_MAX_SAMPLES_IN
      },
      '{
          TASK_12_DATA_WIDTH_IN,
          TASK_12_DATA_WIDTH_OUT,
          TASK_12_INPUT_STREAMS,
          TASK_12_OUTPUT_STREAMS,
          TASK_12_MAX_SAMPLES_IN
      },
      '{
          TASK_13_DATA_WIDTH_IN,
          TASK_13_DATA_WIDTH_OUT,
          TASK_13_INPUT_STREAMS,
          TASK_13_OUTPUT_STREAMS,
          TASK_13_MAX_SAMPLES_IN
      },
      '{
          TASK_14_DATA_WIDTH_IN,
          TASK_14_DATA_WIDTH_OUT,
          TASK_14_INPUT_STREAMS,
          TASK_14_OUTPUT_STREAMS,
          TASK_14_MAX_SAMPLES_IN
      }
  };

endpackage
