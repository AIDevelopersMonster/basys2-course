--------------------------------------------------------------------------------
-- 1-to-4 DeMultiplexer (combinational)
-- din goes to exactly one output selected by s; others are 0.
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity demux_1to4 is
  port (
    din : in  std_logic;
    s   : in  std_logic_vector(1 downto 0);
    y   : out std_logic_vector(3 downto 0)  -- Y0..Y3
  );
end demux_1to4;

architecture RTL of demux_1to4 is
begin
  process(din, s)
  begin
    y <= (others => '0');

    if din = '1' then
      case s is
        when "00" => y(0) <= '1';
        when "01" => y(1) <= '1';
        when "10" => y(2) <= '1';
        when "11" => y(3) <= '1';
        when others => y <= (others => '0');
      end case;
    end if;
  end process;
end RTL;
