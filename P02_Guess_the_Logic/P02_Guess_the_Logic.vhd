library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity P02_Guess_the_Logic is
  port (
    SW  : in  std_logic_vector(7 downto 0);
    LED : out std_logic_vector(7 downto 0)
  );
end P02_Guess_the_Logic;

architecture rtl of P02_Guess_the_Logic is
begin
  -- Остальные LED выключены
  LED(7 downto 3) <= (others => '0');

  -- Circuit 1: SW0 XOR SW1 -> LED0
  LED(0) <= SW(0) xor SW(1);

  -- Circuit 2: SW1,SW2,SW3 -> LED1
  LED(1) <= ((not SW(3)) and (not SW(2)) and (not SW(1))) or
            ((not SW(3)) and      SW(2)  and      SW(1))  or
            (     SW(3)  and (not SW(2)) and      SW(1));

  -- Circuit 3: SW4,SW5,SW6,SW7 -> LED2
  LED(2) <= ((not SW(7)) and (not SW(6)) and (not SW(5)) and      SW(4)) or
            ((not SW(7)) and (not SW(6)) and      SW(5)  and      SW(4)) or
            ((not SW(7)) and      SW(6)  and (not SW(5)) and (not SW(4))) or
            (     SW(7)  and      SW(6)  and      SW(5)  and      SW(4));
end rtl;
