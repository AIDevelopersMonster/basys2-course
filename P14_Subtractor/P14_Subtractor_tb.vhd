library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity P14_Subtractor_tb is
end P14_Subtractor_tb;

architecture Behavioral of P14_Subtractor_tb is

  signal SW  : std_logic_vector(7 downto 0);
  signal LED : std_logic_vector(7 downto 0);

begin

  DUT: entity work.P14_Subtractor
    port map (
      SW  => SW,
      LED => LED
    );

  stim_proc: process
  begin
    SW <= (others => '0');
    wait for 10 ns;

    -- 5 - 3 = 2
    SW(3 downto 0) <= "0101";
    SW(7 downto 4) <= "0011";
    wait for 10 ns;

    -- 3 - 5 = borrow
    SW(3 downto 0) <= "0011";
    SW(7 downto 4) <= "0101";
    wait for 10 ns;

    -- 8 - 1 = 7
    SW(3 downto 0) <= "1000";
    SW(7 downto 4) <= "0001";
    wait for 10 ns;

    wait;
  end process;

end Behavioral;
