library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity half_adder is
  port (
    A    : in  std_logic;
    B    : in  std_logic;
    SUM  : out std_logic;
    COUT : out std_logic
  );
end half_adder;

architecture RTL of half_adder is
begin
  SUM  <= A xor B;
  COUT <= A and B;
end RTL;
