--------------------------------------------------------------------------------
-- Project 6: Priority Encoder (8-to-3) with VALID
-- Board   : Digilent Basys2
-- Language: VHDL
--
-- Назначение:
--   Приоритетный шифратор 8→3:
--     X(7:0) = SW(7:0)
--     Y(2:0) = код номера самого старшего установленного бита (7 имеет max приоритет)
--     V      = признак "есть хотя бы одна 1" (valid)
--
-- Вывод на LED:
--   LED(2:0) = Y(2:0)
--   LED(3)   = V
--   LED(7:4) = 0
--
-- Примечание:
--   Комбинаторная логика, reset не нужен.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity P06_PriorityEncoder is
  port (
    SW  : in  std_logic_vector(7 downto 0);
    LED : out std_logic_vector(7 downto 0)
  );
end P06_PriorityEncoder;

architecture RTL of P06_PriorityEncoder is
  signal x : std_logic_vector(7 downto 0);
  signal y : std_logic_vector(2 downto 0);
  signal v : std_logic;
begin
  x <= SW;

  process(x)
  begin
    -- значения по умолчанию (важно для корректного синтеза без latch)
    y <= "000";
    v <= '0';

    -- приоритет: от старшего бита к младшему
    if    x(7) = '1' then y <= "111"; v <= '1';
    elsif x(6) = '1' then y <= "110"; v <= '1';
    elsif x(5) = '1' then y <= "101"; v <= '1';
    elsif x(4) = '1' then y <= "100"; v <= '1';
    elsif x(3) = '1' then y <= "011"; v <= '1';
    elsif x(2) = '1' then y <= "010"; v <= '1';
    elsif x(1) = '1' then y <= "001"; v <= '1';
    elsif x(0) = '1' then y <= "000"; v <= '1';
    else
      y <= "000";
      v <= '0';
    end if;
  end process;

  LED <= "0000" & v & y;  -- [7..4]=0000, [3]=V, [2..0]=Y

end RTL;
