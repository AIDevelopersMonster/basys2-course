library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================================
-- P18 - 32-bit Counter + "Human" LEDs (Basys2)
-- - 32-bit free-running binary counter on MCLK
-- - LED shows the slow (human-visible) bits:
--     SW7=0 -> LED = cnt(31 downto 24)  (very slow)
--     SW7=1 -> LED = cnt(27 downto 20)  (faster)
-- - BTN0 resets the counter to 0
-- =============================================================================

entity P18_Counter32_HumanLED is
  port (
    MCLK : in  std_logic;                    -- system clock (e.g., 50 MHz)
    SW   : in  std_logic_vector(7 downto 0);  -- use SW7 as display speed select
    BTN  : in  std_logic_vector(3 downto 0);  -- BTN0 = reset
    LED  : out std_logic_vector(7 downto 0)
  );
end P18_Counter32_HumanLED;

architecture Behavioral of P18_Counter32_HumanLED is
  signal cnt : unsigned(31 downto 0) := (others => '0');
begin

  -- 32-bit synchronous counter
  process(MCLK)
  begin
    if rising_edge(MCLK) then
      if BTN(0) = '1' then
        cnt <= (others => '0');
      else
        cnt <= cnt + 1;
      end if;
    end if;
  end process;

  -- Human-visible LED window select
  process(cnt, SW)
  begin
    if SW(7) = '0' then
      LED <= std_logic_vector(cnt(31 downto 24)); -- slow
    else
      LED <= std_logic_vector(cnt(27 downto 20)); -- faster
    end if;
  end process;

end Behavioral;
