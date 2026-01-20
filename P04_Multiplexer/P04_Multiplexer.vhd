--------------------------------------------------------------------------------
-- Project 4: Multiplexer (4-to-1)
-- Board   : Digilent Basys2
-- Language: VHDL
--
-- Назначение:
--   Реализовать 4→1 мультиплексор:
--     D0..D3 берутся с SW(0..3)
--     S(1..0) берутся с SW(5..4)
--     Y выводится на LED(0)
--
-- Доп. индикация (для наглядности):
--   LED(4..1) = one-hot код выбранного входа (D0..D3)
--   LED(7..5) = 0
--
-- Примечание:
--   Логика комбинаторная, reset не требуется.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity P04_Multiplexer is
  port (
    SW  : in  std_logic_vector(7 downto 0);
    LED : out std_logic_vector(7 downto 0)
  );
end P04_Multiplexer;

architecture RTL of P04_Multiplexer is
  signal d        : std_logic_vector(3 downto 0);
  signal s        : std_logic_vector(1 downto 0);
  signal y        : std_logic;
  signal sel_1hot : std_logic_vector(3 downto 0);
begin
  -- Раскладка входов
  d <= SW(3 downto 0);   -- D0..D3
  s <= SW(5 downto 4);   -- S0..S1 (вектор S(1 downto 0))

  -- 4→1 MUX (поведенчески через case)
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

  -- One-hot индикация выбора (для LED(4..1))
  sel_1hot <= "0001" when s = "00" else
              "0010" when s = "01" else
              "0100" when s = "10" else
              "1000" when s = "11" else
              "0000";

  -- Единый драйвер на LED: [7..5]=000, [4..1]=sel_1hot, [0]=y
  LED <= "000" & sel_1hot & y;

end RTL;
