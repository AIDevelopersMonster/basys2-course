library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity P13_Adder_Top is
  port (
    SW  : in  std_logic_vector(7 downto 0);
    BTN : in  std_logic_vector(3 downto 0);
    LED : out std_logic_vector(7 downto 0)
  );
end P13_Adder_Top;

architecture RTL of P13_Adder_Top is
  signal sum  : std_logic_vector(3 downto 0);
  signal cout : std_logic;
begin
  U_ADDER: entity work.adder_4bit
    port map (
      A    => SW(3 downto 0),
      B    => SW(7 downto 4),
      CIN  => BTN(0),
      SUM  => sum,
      COUT => cout
    );

  LED(3 downto 0) <= sum;
  LED(4)          <= cout;
  LED(7 downto 5) <= (others => '0');
end RTL;
