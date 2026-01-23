library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity P12_Comparator_Top is
  port (
    SW  : in  std_logic_vector(7 downto 0);
    LED : out std_logic_vector(7 downto 0)
  );
end P12_Comparator_Top;

architecture RTL of P12_Comparator_Top is
  signal A4, B4 : std_logic_vector(3 downto 0);
  signal GT, LT, EQ : std_logic;
begin
  A4 <= SW(3 downto 0);
  B4 <= SW(7 downto 4);

  U_CMP: entity work.cmp_nbit
    generic map (N => 4)
    port map (
      A  => A4,
      B  => B4,
      GT => GT,
      LT => LT,
      EQ => EQ
    );

  LED <= "00000" & GT & EQ & LT;
end RTL;
