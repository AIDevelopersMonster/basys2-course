--------------------------------------------------------------------------------
-- Testbench for Project 6: Priority Encoder (8-to-3) with VALID
-- Проверка:
--   Перебор всех X(7:0) = 0..255
--   Контроль:
--     V = 1, если X != 0
--     Y = индекс старшего установленного бита (7..0) при X != 0
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_P06_PriorityEncoder is
end tb_P06_PriorityEncoder;

architecture TB of tb_P06_PriorityEncoder is
  signal SW  : std_logic_vector(7 downto 0) := (others => '0');
  signal LED : std_logic_vector(7 downto 0);

  -- функция: найти индекс старшего установленного бита (0..7)
  function msb_index(x : std_logic_vector(7 downto 0)) return integer is
  begin
    for i in 7 downto 0 loop
      if x(i) = '1' then
        return i;
      end if;
    end loop;
    return 0; -- если x=0, значение неважно, т.к. V=0
  end function;

begin
  DUT: entity work.P06_PriorityEncoder
    port map (
      SW  => SW,
      LED => LED
    );

  stim: process
    variable x       : std_logic_vector(7 downto 0);
    variable exp_v   : std_logic;
    variable exp_y_i : integer;
    variable exp_y   : std_logic_vector(2 downto 0);
  begin
    SW <= (others => '0');
    wait for 20 ns;

    for val in 0 to 255 loop
      x := std_logic_vector(to_unsigned(val, 8));
      SW <= x;
      wait for 10 ns;

      if val = 0 then
        exp_v := '0';
        exp_y := "000";
      else
        exp_v   := '1';
        exp_y_i := msb_index(x);
        exp_y   := std_logic_vector(to_unsigned(exp_y_i, 3));
      end if;

      assert LED(3) = exp_v
        report "FAIL: V mismatch at X=" & integer'image(val)
        severity error;

      assert LED(2 downto 0) = exp_y
        report "FAIL: Y mismatch at X=" & integer'image(val)
        severity error;
    end loop;

    report "TB PASSED: all 256 vectors OK." severity note;
    wait;
  end process;

end TB;
