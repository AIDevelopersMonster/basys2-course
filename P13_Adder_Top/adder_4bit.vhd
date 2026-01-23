library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity adder_4bit is
  port (
    A    : in  std_logic_vector(3 downto 0);
    B    : in  std_logic_vector(3 downto 0);
    CIN  : in  std_logic;
    SUM  : out std_logic_vector(3 downto 0);
    COUT : out std_logic
  );
end adder_4bit;

architecture Structural of adder_4bit is
  signal c : std_logic_vector(4 downto 0);
begin
  c(0) <= CIN;

  FA0: entity work.full_adder port map(A(0), B(0), c(0), SUM(0), c(1));
  FA1: entity work.full_adder port map(A(1), B(1), c(1), SUM(1), c(2));
  FA2: entity work.full_adder port map(A(2), B(2), c(2), SUM(2), c(3));
  FA3: entity work.full_adder port map(A(3), B(3), c(3), SUM(3), c(4));

  COUT <= c(4);
end Structural;
