--------------------------------------------------------------------------------
-- Project 5: Decoder (3-to-8) with Enable
-- Board   : Digilent Basys2
-- Language: VHDL
--
-- :
--    38 (one-hot):
--     A(2:0) = SW(2:0)
--     EN     = SW(3)
--     Y(7:0) = LED(7:0)
--
-- :
--   EN=0  => Y = "00000000"
--   EN=1  =>    Y(i)=1,  i = A
--
-- :
--    , reset  .
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity P05_Decoder is
  port (
    SW  : in  std_logic_vector(7 downto 0);
    LED : out std_logic_vector(7 downto 0)
  );
end P05_Decoder;

architecture RTL of P05_Decoder is
  signal a  : std_logic_vector(2 downto 0);
  signal en : std_logic;
  signal y  : std_logic_vector(7 downto 0);
begin
  a  <= SW(2 downto 0);
  en <= SW(3);

  -- 38 decoder (one-hot)  
  process(a, en)
  begin
    --   ,     (latch)
    y <= (others => '0');

    if en = '1' then
      case a is
        when "000" => y <= "00000001";
        when "001" => y <= "00000010";
        when "010" => y <= "00000100";
        when "011" => y <= "00001000";
        when "100" => y <= "00010000";
        when "101" => y <= "00100000";
        when "110" => y <= "01000000";
        when "111" => y <= "10000000";
        when others => y <= (others => '0');
      end case;
    end if;
  end process;

  LED <= y;

end RTL;
