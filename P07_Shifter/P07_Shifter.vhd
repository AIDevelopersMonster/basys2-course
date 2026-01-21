--------------------------------------------------------------------------------
-- Project 7: Barrel Shifter (4-bit) - Combinational
-- Board   : Digilent Basys2
-- Language: VHDL
--
-- Назначение:
--   Комбинаторный "barrel shifter" (быстрый сдвиг на 0..3 за один такт логики)
--
-- Входы (SW):
--   SW(3:0) = A(3:0)   данные
--   SW(5:4) = SH(1:0)  величина сдвига (0..3)
--   SW(6)   = DIR      направление: 0=влево, 1=вправо
--   SW(7)   = FILL     бит заполнения освобождающихся разрядов
--
-- Выходы (LED):
--   LED(3:0) = Y(3:0)  результат
--   LED(7:4) = A(3:0)  отображение исходных данных (для наглядности)
--
-- Примечание:
--   Логика комбинаторная, reset не требуется.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity P07_Shifter is
  port (
    SW  : in  std_logic_vector(7 downto 0);
    LED : out std_logic_vector(7 downto 0)
  );
end P07_Shifter;

architecture RTL of P07_Shifter is
  signal a    : std_logic_vector(3 downto 0);
  signal sh   : std_logic_vector(1 downto 0);
  signal dir  : std_logic;
  signal fill : std_logic;
  signal y    : std_logic_vector(3 downto 0);
begin
  a    <= SW(3 downto 0);
  sh   <= SW(5 downto 4);
  dir  <= SW(6);
  fill <= SW(7);

  process(a, sh, dir, fill)
  begin
    -- по умолчанию
    y <= a;

    if dir = '0' then
      -- СДВИГ ВЛЕВО
      case sh is
        when "00" => y <= a;
        when "01" => y <= a(2 downto 0) & fill;
        when "10" => y <= a(1 downto 0) & fill & fill;
        when "11" => y <= a(0) & fill & fill & fill;
        when others => y <= a;
      end case;
    else
      -- СДВИГ ВПРАВО
      case sh is
        when "00" => y <= a;
        when "01" => y <= fill & a(3 downto 1);
        when "10" => y <= fill & fill & a(3 downto 2);
        when "11" => y <= fill & fill & fill & a(3);
        when others => y <= a;
      end case;
    end if;
  end process;

  -- LED(7:4) показываем исходный A, LED(3:0) - результат Y
  LED <= a & y;

end RTL;
