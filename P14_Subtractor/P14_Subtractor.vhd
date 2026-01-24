library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity P14_Subtractor is
  port (
    SW  : in  std_logic_vector(7 downto 0);
    LED : out std_logic_vector(7 downto 0)
  );
end P14_Subtractor;

architecture Behavioral of P14_Subtractor is

  signal A, B : std_logic_vector(3 downto 0);
  signal D    : std_logic_vector(3 downto 0);
  signal bor  : std_logic_vector(4 downto 0);

begin

  A <= SW(3 downto 0);
  B <= SW(7 downto 4);

  bor(0) <= '0';

  gen_sub: for i in 0 to 3 generate
    D(i) <= A(i) xor B(i) xor bor(i);

    bor(i+1) <= (not A(i) and B(i)) or
                (bor(i) and not (A(i) xor B(i)));
  end generate;

  LED(3 downto 0) <= D;
  LED(7)          <= bor(4);
  LED(6 downto 4) <= (others => '0');

end Behavioral;
