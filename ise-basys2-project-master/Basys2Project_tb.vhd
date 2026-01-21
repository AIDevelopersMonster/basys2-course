-- ============================================================================
--  Testbench: Basys2Project_tb
--  Target   : Digilent Basys 2 (Spartan-3E)
--  Tool     : Xilinx ISE / ISim (Behavioral Simulation)
--
--  Назначение:
--    Шаблон тестбенча для функциональной (behavioral) симуляции.
--    Здесь нет привязок к пинам (UCF не используется в симуляции).
--
--  Как пользоваться:
--    1) Откройте проект в ISE и добавьте этот файл, если он не добавился.
--    2) Сделайте entity <project>_tb верхним модулем для Simulation.
--    3) Доработайте процесс stimulus под свою лабораторную.
--
--  Примечание:
--    INOUT-порты оставлены в Z (высокоимпедансное состояние).
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Basys2Project_tb is
end Basys2Project_tb;

architecture sim of Basys2Project_tb is

  -- Clock period settings
  constant MCLK_PERIOD : time := 20 ns;  -- 50 MHz
  constant UCLK_PERIOD : time := 40 ns;  -- 25 MHz (пример)

  -- DUT I/O
  signal MCLK      : std_logic := '0';
  signal UCLK      : std_logic := '0';
  signal BTN       : std_logic_vector(3 downto 0) := (others => '0');
  signal SW        : std_logic_vector(7 downto 0) := (others => '0');

  signal LED       : std_logic_vector(7 downto 0);
  signal SEG       : std_logic_vector(6 downto 0);
  signal AN        : std_logic_vector(3 downto 0);
  signal DP        : std_logic;

  signal VGA_RED   : std_logic_vector(2 downto 0);
  signal VGA_GREEN : std_logic_vector(2 downto 0);
  signal VGA_BLUE  : std_logic_vector(2 downto 1);
  signal VGA_HS    : std_logic;
  signal VGA_VS    : std_logic;

  signal PS2C      : std_logic := 'Z';
  signal PS2D      : std_logic := 'Z';

  signal PIO       : std_logic_vector(87 downto 72) := (others => 'Z');

  signal EppAstb   : std_logic := '0';
  signal EppDstb   : std_logic := '0';
  signal EppWr     : std_logic := '0';
  signal EppWait   : std_logic;
  signal EppDB     : std_logic_vector(7 downto 0) := (others => 'Z');

begin

  -- =====================
  --  DUT instantiation
  -- =====================
  UUT: entity work.Basys2Project
    port map (
      MCLK      => MCLK,
      UCLK      => UCLK,
      BTN       => BTN,
      SW        => SW,
      LED       => LED,
      SEG       => SEG,
      AN        => AN,
      DP        => DP,
      VGA_RED   => VGA_RED,
      VGA_GREEN => VGA_GREEN,
      VGA_BLUE  => VGA_BLUE,
      VGA_HS    => VGA_HS,
      VGA_VS    => VGA_VS,
      PS2C      => PS2C,
      PS2D      => PS2D,
      PIO       => PIO,
      EppAstb   => EppAstb,
      EppDstb   => EppDstb,
      EppWr     => EppWr,
      EppWait   => EppWait,
      EppDB     => EppDB
    );

  -- =====================
  --  Clock generators
  -- =====================
  clk_mclk: process
  begin
    MCLK <= '0';
    wait for MCLK_PERIOD/2;
    MCLK <= '1';
    wait for MCLK_PERIOD/2;
  end process;

  clk_uclk: process
  begin
    UCLK <= '0';
    wait for UCLK_PERIOD/2;
    UCLK <= '1';
    wait for UCLK_PERIOD/2;
  end process;

  -- =====================
  --  Stimulus
  -- =====================
  stimulus: process
  begin
    -- Стартовое состояние
    BTN <= (others => '0');
    SW  <= (others => '0');
    wait for 200 ns;

    -- Пример: перебор значений SW
    SW <= x"01";
    wait for 200 ns;
    SW <= x"AA";
    wait for 200 ns;
    SW <= x"FF";
    wait for 200 ns;

    -- Пример: нажатие кнопки BTN0
    BTN(0) <= '1';
    wait for 100 ns;
    BTN(0) <= '0';
    wait for 300 ns;

    -- Оставляем симуляцию "бежать" дальше
    wait;
  end process;

end sim;
