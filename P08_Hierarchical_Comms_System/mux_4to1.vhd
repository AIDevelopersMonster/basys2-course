--------------------------------------------------------------------------------
-- 4-to-1 Multiplexer (combinational)
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux_4to1 is
  port (
    d : in  std_logic_vector(3 downto 0);  -- inputs D0..D3
    s : in  std_logic_vector(1 downto 0);  -- select S1..S0
    y : out std_logic                      -- output
  );
end mux_4to1;

architecture RTL of mux_4to1 is
begin
  process(d, s)
  begin
    case s is
      when "00" => y <= d(0);
      when "01" => y <= d(1);
      when "10" => y <= d(2);
      when "11" => y <= d(3);
      when others => y <= '0';
    end case;
  end process;
end RTL;
