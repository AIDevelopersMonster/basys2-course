library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity P18_Counter32_HumanLED_tb is
end P18_Counter32_HumanLED_tb;

architecture TB of P18_Counter32_HumanLED_tb is

  signal MCLK : std_logic := '0';
  signal SW   : std_logic_vector(7 downto 0) := (others => '0');
  signal BTN  : std_logic_vector(3 downto 0) := (others => '0');
  signal LED  : std_logic_vector(7 downto 0);

  constant CLK_PERIOD : time := 20 ns; -- 50 MHz

begin

  -- DUT
  uut: entity work.P18_Counter32_HumanLED
    port map (
      MCLK => MCLK,
      SW   => SW,
      BTN  => BTN,
      LED  => LED
    );

  -- Clock
  MCLK <= not MCLK after CLK_PERIOD/2;

  -- Stimulus
  process
  begin
    -- start: SW7=0 (slow window)
    SW(7) <= '0';
    BTN(0) <= '1';           -- reset asserted
    wait for 5*CLK_PERIOD;
    BTN(0) <= '0';           -- release reset

    -- run some cycles
    wait for 200*CLK_PERIOD;

    -- switch to faster window
    SW(7) <= '1';
    wait for 200*CLK_PERIOD;

    -- hit reset again
    BTN(0) <= '1';
    wait for 10*CLK_PERIOD;
    BTN(0) <= '0';

    wait for 200*CLK_PERIOD;

    -- done
    wait;
  end process;

end TB;
