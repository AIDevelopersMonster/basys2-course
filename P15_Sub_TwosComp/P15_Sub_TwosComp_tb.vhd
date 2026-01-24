library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity P15_Sub_TwosComp_tb is
end P15_Sub_TwosComp_tb;

architecture Behavioral of P15_Sub_TwosComp_tb is

  signal SW  : std_logic_vector(7 downto 0);
  signal LED : std_logic_vector(7 downto 0);

begin

  DUT: entity work.P15_Sub_TwosComp
    port map (
      SW  => SW,
      LED => LED
    );

  stim: process
  begin
    -- init (важно: убирает U/X)
    SW <= (others => '0');
    wait for 10 ns;

    -- Case 1: A=5, B=3 => 2
    -- SW = B A = 0011 0101
    SW <= "00110101";
    wait for 10 ns;

    -- Case 2: A=3, B=5 => -2 (two's complement: 1110)
    -- SW = 0101 0011
    SW <= "01010011";
    wait for 10 ns;

    -- Case 3: A=8, B=1 => 7
    -- SW = 0001 1000
    SW <= "00011000";
    wait for 10 ns;

    -- Case 4: A=0, B=1 => -1 (1111)
    -- SW = 0001 0000
    SW <= "00010000";
    wait for 10 ns;

    -- Case 5: A=0, B=0 => 0
    -- SW = 0000 0000
    SW <= "00000000";
    wait for 10 ns;

    wait;
  end process;

end Behavioral;
