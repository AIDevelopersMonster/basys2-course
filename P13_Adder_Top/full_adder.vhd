library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity full_adder is
  port (
    A    : in  std_logic;
    B    : in  std_logic;
    CIN  : in  std_logic;
    SUM  : out std_logic;
    COUT : out std_logic
  );
end full_adder;

architecture Structural of full_adder is
  signal s1, c1, c2 : std_logic;
begin
  HA1: entity work.half_adder
    port map (A => A, B => B, SUM => s1, COUT => c1);

  HA2: entity work.half_adder
    port map (A => s1, B => CIN, SUM => SUM, COUT => c2);

  COUT <= c1 or c2;
end Structural;
