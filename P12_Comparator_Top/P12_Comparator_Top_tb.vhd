library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_P12_Comparator_Top is
end;

architecture TB of tb_P12_Comparator_Top is
  signal SW  : std_logic_vector(7 downto 0) := (others => '0');
  signal LED : std_logic_vector(7 downto 0);
begin
  DUT: entity work.P12_Comparator_Top
    port map (SW => SW, LED => LED);

  process
    variable a, b : integer;
  begin
    -- начальные значения (не U!)
    SW <= (others => '0');
    wait for 10 ns;

    -- пример: A=9, B=6 => SW = 0110_1001
    SW <= "01101001";
    wait for 10 ns;

    -- полный перебор 0..15 (по желанию)
    for a in 0 to 15 loop
      for b in 0 to 15 loop
        SW <= std_logic_vector(to_unsigned(b,4)) & std_logic_vector(to_unsigned(a,4));
        wait for 1 ns;
      end loop;
    end loop;

    wait;
  end process;
end;
