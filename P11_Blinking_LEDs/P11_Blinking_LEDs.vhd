--------------------------------------------------------------------------------
-- Project 11: Blinking LEDs (Basys2, VHDL)
--
-- Ports:
--   MCLK : board clock (usually 50 MHz; depends on JP4 setting)
--   BTN(0) : reset (active-high)
--   SW(1:0) : speed select 00/01/10/11 => 1/2/4/8 Hz
--   SW(2)   : mode 0=blink all, 1=running light (ring)
--   LED(7:0): output pattern
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity P11_Blinking_LEDs is
  generic (
    CLK_HZ : positive := 50_000_000  -- set to your actual MCLK frequency
  );
  port (
    MCLK : in  std_logic;
    BTN  : in  std_logic_vector(3 downto 0);
    SW   : in  std_logic_vector(7 downto 0);
    LED  : out std_logic_vector(7 downto 0)
  );
end P11_Blinking_LEDs;

architecture RTL of P11_Blinking_LEDs is
  signal leds       : std_logic_vector(7 downto 0) := (others => '0');
  signal cnt        : unsigned(31 downto 0) := (others => '0');

  signal mode       : std_logic := '0';
  signal speed      : std_logic_vector(1 downto 0) := "00";

  signal mode_prev  : std_logic := '0';
  signal speed_prev : std_logic_vector(1 downto 0) := "00";

  -- :    
  constant DIV_1HZ : integer := CLK_HZ / (2*1);
  constant DIV_2HZ : integer := CLK_HZ / (2*2);
  constant DIV_4HZ : integer := CLK_HZ / (2*4);
  constant DIV_8HZ : integer := CLK_HZ / (2*8);

  function sel_div(s : std_logic_vector(1 downto 0)) return integer is
  begin
    case s is
      when "00" => return DIV_1HZ;
      when "01" => return DIV_2HZ;
      when "10" => return DIV_4HZ;
      when others => return DIV_8HZ;
    end case;
  end function;

begin
  mode  <= SW(2);
  speed <= SW(1 downto 0);

  process(MCLK)
    variable div_i : integer;
    variable div_u : unsigned(31 downto 0);
  begin
    if rising_edge(MCLK) then
      div_i := sel_div(speed);
      if div_i < 1 then
        div_i := 1; --   ""    CLK_HZ
      end if;
      div_u := to_unsigned(div_i - 1, cnt'length);

      if BTN(0) = '1' then
        cnt        <= (others => '0');
        leds       <= (others => '0');
        mode_prev  <= mode;
        speed_prev <= speed;

      else
        --    -  
        if mode /= mode_prev then
          cnt       <= (others => '0');
          mode_prev <= mode;

          if mode = '1' then
            leds <= "00000001"; --   
          else
            leds <= (others => '0'); --  
          end if;

        --    -   
        elsif speed /= speed_prev then
          cnt        <= (others => '0');
          speed_prev <= speed;

        --  
        elsif cnt = div_u then
          cnt <= (others => '0');

          if mode = '0' then
            leds <= not leds;  --  
          else
            leds <= leds(6 downto 0) & leds(7); --   (ring)
          end if;

        else
          cnt <= cnt + 1;
        end if;
      end if;
    end if;
  end process;

  LED <= leds;

end RTL;
