library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- P15: Subtraction via Two's Complement
-- A - B = A + (~B) + 1
--
-- Basys 2 mapping (same convention as P14):
-- SW7..SW4 = B[3:0]
-- SW3..SW0 = A[3:0]
--
-- Outputs:
-- LED3..LED0 = Result[3:0] (two's complement)
-- LED7       = Sign bit (Result(3))
-- LED6       = Carry out (useful for analysis; optional)
-- LED5..LED4 = 0

entity P15_Sub_TwosComp is
  port (
    SW  : in  std_logic_vector(7 downto 0);
    LED : out std_logic_vector(7 downto 0)
  );
end P15_Sub_TwosComp;

architecture Behavioral of P15_Sub_TwosComp is

  signal A      : std_logic_vector(3 downto 0);
  signal B      : std_logic_vector(3 downto 0);
  signal Bn     : std_logic_vector(3 downto 0); -- ~B
  signal R      : std_logic_vector(3 downto 0);
  signal c      : std_logic_vector(4 downto 0); -- carry chain

begin

  -- Split switches into nibbles by physical row convention
  A <= SW(3 downto 0);
  B <= SW(7 downto 4);

  -- Two's complement transform: ~B + 1 (implemented as Cin=1)
  Bn <= not B;

  -- Add with initial carry = 1
  c(0) <= '1';

  gen_add: for i in 0 to 3 generate
    -- Sum bit
    R(i) <= A(i) xor Bn(i) xor c(i);

    -- Carry out
    c(i+1) <= (A(i) and Bn(i)) or
              (A(i) and c(i)) or
              (Bn(i) and c(i));
  end generate;

  -- LEDs
  LED(3 downto 0) <= R;
  LED(7)          <= R(3);   -- sign bit in two's complement
  LED(6)          <= c(4);   -- carry out (analysis)
  LED(5 downto 4) <= (others => '0');

end Behavioral;
