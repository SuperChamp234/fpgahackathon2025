library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pl_controller is
  Port (
    clk                 : in std_logic;
    resetn              : in std_logic;
    tv_in_ready         : in std_logic;
    tasks_done          : in std_logic;
    tv_out_rcv_ack      : in std_logic;
    pl_ready            : out std_logic;
    pl_ready_wr_en      : out std_logic;
    tv_out_ready        : out std_logic;
    tv_out_ready_wr_en  : out std_logic;
    regs_wr_busy        : in std_logic;
    start_tests         : out std_logic
  );
end pl_controller;

architecture Behavioral of pl_controller is

type state is (IDLE, WAIT_FOR_NEW_TV, START_TASKS, WAIT_FOR_TASKS_DONE, TEST_DONE);
signal exec_state : state;
signal pl_ready_state, tv_out_ready_state : std_logic;
signal pl_ready_r, tv_out_ready_r : std_logic;

begin

state_machine: process(clk) is
begin
  if rising_edge(clk) then
    if resetn = '0' then
      exec_state <= IDLE;
    else
      case exec_state is
        when IDLE =>
          exec_state <= WAIT_FOR_NEW_TV;
        when WAIT_FOR_NEW_TV =>
          if tv_in_ready = '1' then
            exec_state <= START_TASKS;
          else
            exec_state <= WAIT_FOR_NEW_TV;
          end if;
        when START_TASKS =>
          exec_state <= WAIT_FOR_TASKS_DONE;
        when WAIT_FOR_TASKS_DONE =>
          if tasks_done = '1' then
            exec_state <= TEST_DONE;
          else
            exec_state <= WAIT_FOR_TASKS_DONE;
          end if;
        when TEST_DONE =>
          if tv_out_rcv_ack = '1' then
            exec_state <= WAIT_FOR_NEW_TV;
          else
            exec_state <= TEST_DONE;
          end if;
      end case;
    end if;
  end if;
end process state_machine;


state_machine_execution: process(clk) is
begin
  if rising_edge(clk) then
    case exec_state is 
      when IDLE =>
        pl_ready_state     <= '0';
        tv_out_ready_state <= '0';
        start_tests        <= '0';
      when WAIT_FOR_NEW_TV =>
        pl_ready_state     <= '1';
        tv_out_ready_state <= '0';
        start_tests        <= '0';
      when START_TASKS =>
        pl_ready_state     <= '1';
        tv_out_ready_state <= '0';
        start_tests        <= '1';
      when WAIT_FOR_TASKS_DONE =>
        pl_ready_state     <= '1';
        tv_out_ready_state <= '0';
        start_tests        <= '0';
      when TEST_DONE =>
        pl_ready_state     <= '1';
        tv_out_ready_state <= '1';
        start_tests        <= '0';
    end case;
  end if;
end process state_machine_execution;


output_write_pl_ready: process(clk)
variable wr_to_be_done, wr_done : std_logic;
begin
  if rising_edge(clk) then
    if (resetn = '0') then
      pl_ready_r    <= '0';
      wr_done       := '0';
      wr_to_be_done := '0';
    else
      if (wr_done = '1') then
        pl_ready_r     <= '0';
        pl_ready_wr_en <= '0';
        wr_done        := '1';
      else
        if pl_ready_state = '1' then
          wr_to_be_done := '1';
        else
          wr_to_be_done := wr_to_be_done;
        end if;
        if (wr_to_be_done = '1' and regs_wr_busy = '0') then
          pl_ready_r     <= '1';
          pl_ready_wr_en <= '1';
          wr_done        := '1';
        else
          pl_ready_r     <= '0';
          pl_ready_wr_en <= '0';
          wr_done        := '0';
        end if;
      end if;
    end if;
  end if;
end process output_write_pl_ready;


-- output_write_tv_out_ready: process(clk)
-- variable set_to_be_done, set_done, reset_to_be_done, reset_done : std_logic;
-- begin
--   if rising_edge(clk) then
--     if (resetn = '0') then
--       tv_out_ready_r     <= '0';
--       set_done           := '0';
--       set_to_be_done     := '0';
--       reset_done         := '0';
--       reset_to_be_done   := '0';
--     else
--       if (set_done = '1') then
--         tv_out_ready_r      <= '0';
--         tv_out_ready_wr_en  <= '0';
--         set_done            := '1';
--       else
--         if tv_out_ready_state = '1' then
--           set_to_be_done := '1';
--         else
--           set_to_be_done := set_to_be_done;
--         end if;
--         if (set_to_be_done = '1' and regs_wr_busy = '0') then
--           tv_out_ready_r      <= '1';
--           tv_out_ready_wr_en  <= '1';
--           set_done            := '1';
--         else
--           tv_out_ready_r      <= '0';
--           tv_out_ready_wr_en  <= '0';
--           set_done            := '0';
--         end if;
--       end if;
--     end if;
--   end if;
-- end process output_write_tv_out_ready;

output_write_tv_out_ready: process(clk)
  variable set_to_be_done, set_done, reset_to_be_done, reset_done : std_logic;
  begin
    if rising_edge(clk) then
      if (resetn = '0') then
        tv_out_ready_r     <= '0';
        set_done           := '0';
        set_to_be_done     := '0';
        reset_done         := '0';
        reset_to_be_done   := '0';
      else
        if tv_out_ready_state = '1' then
          set_to_be_done := '1';

          if (set_done = '1') then
            tv_out_ready_r      <= '0';
            tv_out_ready_wr_en  <= '0';
            set_done            := '1';
            set_to_be_done      := '0';
          end if;

          if (set_to_be_done = '1' and regs_wr_busy = '0') then
            tv_out_ready_r      <= '1';
            tv_out_ready_wr_en  <= '1';
            set_done            := '1';
            reset_done          := '0';
          else
            tv_out_ready_r      <= '0';
            tv_out_ready_wr_en  <= '0';
            set_done            := set_done;
            reset_done          := reset_done;
          end if;
        else
          if set_done = '1' then
            reset_to_be_done := '1';
          else
            reset_to_be_done := '0';
          end if;

          if (reset_done = '1') then
            tv_out_ready_r      <= '0';
            tv_out_ready_wr_en  <= '0';
            reset_done          := '1';
            reset_to_be_done    := '0';
          end if;

          if (reset_to_be_done = '1' and regs_wr_busy = '0') then
            tv_out_ready_r      <= '0';
            tv_out_ready_wr_en  <= '1';
            set_done            := '0';
            reset_done          := '1';
          else
            tv_out_ready_r      <= '0';
            tv_out_ready_wr_en  <= '0';
            set_done            := set_done;
            reset_done          := reset_done;
          end if;

        end if;
      end if;
    end if;
  end process output_write_tv_out_ready;

pl_ready     <= pl_ready_r;
tv_out_ready <= tv_out_ready_r;

end Behavioral;
