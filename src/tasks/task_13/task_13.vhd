library ieee;
use ieee.std_logic_1164.all;

entity task_13 is
  generic(
    TASK_INPUT_WIDTH : integer := 16;
    TASK_OUTPUT_WIDTH : integer := 16;
    INPUT_STREAMS : integer := 1;
    OUTPUT_STREAMS : integer := 1
  );
  port (
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_data : in std_logic_vector(TASK_INPUT_WIDTH-1 downto 0);
    i_valid : in std_logic;
    i_first : in std_logic;
    i_last : in std_logic;
    o_data : out std_logic_vector(TASK_OUTPUT_WIDTH-1 downto 0);
    o_valid : out std_logic;
    o_last : out std_logic

  );
end entity task_13;

architecture rtl of task_13 is

  -- Dummy signals (remove them when you start the implementation)
  signal r_data : std_logic_vector(TASK_OUTPUT_WIDTH-1 downto 0);
  signal r_valid : std_logic;
  signal r_last : std_logic;

--   component ultrasonic_ndt_0
--   port (
--     i_clk : in std_logic;
--     i_rst : in std_logic;
--     i_cfg_data : in std_logic_vector(15 downto 0);
--     i_cfg_valid : in std_logic;
--     i_pwm : in std_logic;
--     o_data : out std_logic_vector(15 downto 0);
--     o_valid : out std_logic;
--     o_last : out std_logic;
--     o_enabled : out std_logic
--   );
--   end component;

begin

  -- Dummy logic (remove it when you start the implementation)
  process(i_clk)
    begin
      if rising_edge(i_clk) then
        if i_rst = '1' then
          r_data <= (others => '0'); -- Reset dummy register
          r_valid <= '0'; -- Reset dummy register
          r_last <= '0'; -- Reset dummy register
        else
        r_data <= i_data; -- Dummy assignment
        r_valid <= i_valid; -- Dummy assignment
        r_last <= i_last; -- Dummy assignment
      end if;
    end if;
  end process;

  -- Output assignments (you can remove these when you start the implementation)
  o_data <= r_data; -- Dummy assignment
  o_valid <= r_valid; -- Dummy assignment: TEMPORARILY CHANGED TO 0, TO CHECK TIMEOUTS (revert this to r_valid assignment)
  o_last <= r_last; -- Dummy assignment

  -- ultrasonic_ndt_inst : ultrasonic_ndt_0
  --   port map(
  --     i_clk => i_clk,
  --     i_rst => i_rst,
  --     i_cfg_data => i_cfg_data,
  --     i_cfg_valid => i_cfg_valid,
  --     i_pwm => i_pwm,
  --     o_data => o_data,
  --     o_valid => o_valid,
  --     o_last => o_last,
  --     o_enabled => o_enabled
  --   );

end architecture rtl;