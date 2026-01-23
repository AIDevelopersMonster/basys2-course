library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_P11_Blinking_LEDs is
end tb_P11_Blinking_LEDs;

architecture TB of tb_P11_Blinking_LEDs is
  signal MCLK : std_logic := '0';
  signal BTN  : std_logic_vector(3 downto 0) := (others => '0');
  signal SW   : std_logic_vector(7 downto 0) := (others => '0');
  signal LED  : std_logic_vector(7 downto 0);

  constant CLK_HZ_SIM : positive := 64; --  ""   
  constant Tclk : time := 10 ns;

  procedure tick(n : natural) is
  begin
    for i in 1 to n loop
      wait until rising_edge(MCLK);
    end loop;
  end procedure;

  --  CLK_HZ_SIM=64  speed="11" (8 Hz):
  -- div = 64/(2*8) = 4   
  constant DIV_FAST : natural := 4;

begin
  -- clock
  MCLK <= not MCLK after Tclk/2;

  DUT: entity work.P11_Blinking_LEDs
    generic map (
      CLK_HZ => CLK_HZ_SIM
    )
    port map (
      MCLK => MCLK,
      BTN  => BTN,
      SW   => SW,
      LED  => LED
    );

  stim: process
  begin
    -- speed=8Hz, mode=blink-all
    SW(1 downto 0) <= "11";
    SW(2) <= '0';

    -- reset
    BTN(0) <= '1';
    tick(3);
    BTN(0) <= '0';
    tick(1);

    assert LED = x"00"
      report "FAIL: after reset LED should be 00"
      severity error;

    -- after DIV_FAST ticks -> invert => FF
    tick(DIV_FAST);
    assert LED = x"FF"
      report "FAIL: blink-all first toggle should be FF"
      severity error;

    -- next toggle -> 00
    tick(DIV_FAST);
    assert LED = x"00"
      report "FAIL: blink-all second toggle should be 00"
      severity error;

    -- switch to running mode; should reinit to 00000001 on next clock
    SW(2) <= '1';
    tick(1);
    assert LED = "00000001"
      report "FAIL: running mode should init to 00000001"
      severity error;

    -- 1st shift -> 00000010
    tick(DIV_FAST);
    assert LED = "00000010"
      report "FAIL: running first step should be 00000010"
      severity error;

    -- 2nd shift -> 00000100
    tick(DIV_FAST);
    assert LED = "00000100"
      report "FAIL: running second step should be 00000100"
      severity error;

    report "TB PASSED." severity note;
    wait;
  end process;

end TB;
