library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity P20_Serial_Adder_FSM_tb is
end;

architecture tb of P20_Serial_Adder_FSM_tb is
  signal clk : std_logic := '0';
  signal btn : std_logic_vector(3 downto 0) := (others => '0');
  signal sw  : std_logic_vector(7 downto 0) := (others => '0');
  signal led : std_logic_vector(7 downto 0);

  constant T : time := 20 ns;

  procedure pulse(signal s: out std_logic; width: time := T) is
  begin
    s <= '1'; wait for width; s <= '0';
  end procedure;

begin
  clk <= not clk after T/2;

  DUT: entity work.P20_Serial_Adder_FSM
    port map (
      MCLK => clk,
      BTN  => btn,
      SW   => sw,
      LED  => led
    );

  process
  begin
    -- init
    btn <= (others => '0');
    sw  <= (others => '0');
    wait for 5*T;

    -- Case: A=3 (0011), B=5 (0101) => SUM=8 (1000), COUT=0
    sw(3 downto 0) <= "0011";
    sw(7 downto 4) <= "0101";

    -- LOAD
    pulse(btn(3));
    wait for 10*T;

    -- 4 STEP pulses; wait enough for FSM to go through SHIFT+CHECK between steps
    for i in 0 to 3 loop
      pulse(btn(0));
      wait for 10*T;
    end loop;

    -- allow ST_DONE settle
    wait for 10*T;

    assert led(3 downto 0) = "1000"
      report "FSM sum incorrect"
      severity error;

    assert led(4) = '0'
      report "FSM carry incorrect"
      severity error;

    report "OK: P20 FSM serial adder passed (A=3, B=5 => 8)";
    wait;
  end process;
end; 