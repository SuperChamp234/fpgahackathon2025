package task_enabler_pkg;

typedef struct packed {
  logic task16; logic task15; logic task14; logic task13; logic task12; logic task11; logic task10; logic task9;
  logic task8;  logic task7;  logic task6;  logic task5;  logic task4;  logic task3;  logic task2;  logic task1;
} task_enabler;

localparam task_enabler enable = '{
  task1 :  1'b0,
  task2 :  1'b0,
  task3 :  1'b0,
  task4 :  1'b0,
  task5 :  1'b0,
  task6 :  1'b0,
  task7 :  1'b0,
  task8 :  1'b0,

  task9 :  1'b0,
  task10 : 1'b0,
  task11 : 1'b0,
  task12 : 1'b0,
  task13 : 1'b0,
  task14 : 1'b0,
  task15 : 1'b0,
  task16 : 1'b0
};

endpackage
