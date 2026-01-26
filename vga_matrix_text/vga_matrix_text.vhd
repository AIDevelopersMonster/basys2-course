-- ============================================================================
-- Basys2 VGA "Matrix" demo (NO DCM, NO derived clocks)
-- Robust method: use 50 MHz MCLK as the ONLY clock, generate pixel-enable @25 MHz.
-- Ports match ONLY uncommented nets from UCF:
--   MCLK
--   VGA_HS, VGA_VS
--   VGA_RED<2:0>, VGA_GREEN<2:0>, VGA_BLUE<2:1>
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Basys2Project is
  port (
    MCLK      : in  std_logic;

    VGA_HS    : out std_logic;
    VGA_VS    : out std_logic;

    VGA_RED   : out std_logic_vector(2 downto 0);
    VGA_GREEN : out std_logic_vector(2 downto 0);
    VGA_BLUE  : out std_logic_vector(2 downto 1)
  );
end Basys2Project;

architecture rtl of Basys2Project is

  -- =========================================================================
  -- Pixel-enable: 50 MHz -> 25 MHz enable (updates happen only when pix_ce='1')
  -- =========================================================================
  signal pix_ce : std_logic := '0';

  -- =========================================================================
  -- VGA 640x480@60 timing (nominal 25.175MHz; 25MHz enable works for most monitors)
  -- =========================================================================
  constant H_VISIBLE : integer := 640;
  constant H_FP      : integer := 16;
  constant H_SYNC    : integer := 96;
  constant H_BP      : integer := 48;
  constant H_TOTAL   : integer := H_VISIBLE + H_FP + H_SYNC + H_BP; -- 800

  constant V_VISIBLE : integer := 480;
  constant V_FP      : integer := 10;
  constant V_SYNC    : integer := 2;
  constant V_BP      : integer := 33;
  constant V_TOTAL   : integer := V_VISIBLE + V_FP + V_SYNC + V_BP; -- 525

  signal h_cnt : unsigned(9 downto 0) := (others => '0'); -- 0..799
  signal v_cnt : unsigned(9 downto 0) := (others => '0'); -- 0..524

  signal visible : std_logic := '0';
  signal hs_n    : std_logic := '1';
  signal vs_n    : std_logic := '1';

  -- PRNG for "rain"
  signal lfsr : unsigned(15 downto 0) := x"ACE1";

  -- Text
  constant CHAR_W  : integer := 8;
  constant CHAR_H  : integer := 8;
  constant MSG_LEN : integer := 23;

  constant TXT_W : integer := MSG_LEN * CHAR_W;
  constant TXT_X : integer := (H_VISIBLE - TXT_W) / 2;
  constant TXT_Y : integer := (V_VISIBLE - CHAR_H) / 2;

  function msg_char(i : integer) return character is
  begin
    case i is
      when  0 => return 'F';
      when  1 => return 'O';
      when  2 => return 'L';
      when  3 => return 'L';
      when  4 => return 'O';
      when  5 => return 'W';
      when  6 => return ' ';
      when  7 => return 'T';
      when  8 => return 'H';
      when  9 => return 'E';
      when 10 => return ' ';
      when 11 => return 'W';
      when 12 => return 'H';
      when 13 => return 'I';
      when 14 => return 'T';
      when 15 => return 'E';
      when 16 => return ' ';
      when 17 => return 'R';
      when 18 => return 'A';
      when 19 => return 'B';
      when 20 => return 'B';
      when 21 => return 'I';
      when 22 => return 'T';
      when others => return ' ';
    end case;
  end function;

  function font8x8(c : character; row : integer) return std_logic_vector is
    variable b : std_logic_vector(7 downto 0) := (others => '0');
  begin
    case c is
      when ' ' => b := "00000000";
      when 'A' =>
        case row is
          when 0 => b := "00111100";
          when 1 => b := "01100110";
          when 2 => b := "01100110";
          when 3 => b := "01111110";
          when 4 => b := "01100110";
          when 5 => b := "01100110";
          when 6 => b := "01100110";
          when others => b := "00000000";
        end case;
      when 'B' =>
        case row is
          when 0 => b := "01111100";
          when 1 => b := "01100110";
          when 2 => b := "01100110";
          when 3 => b := "01111100";
          when 4 => b := "01100110";
          when 5 => b := "01100110";
          when 6 => b := "01111100";
          when others => b := "00000000";
        end case;
      when 'E' =>
        case row is
          when 0 => b := "01111110";
          when 1 => b := "01100000";
          when 2 => b := "01100000";
          when 3 => b := "01111100";
          when 4 => b := "01100000";
          when 5 => b := "01100000";
          when 6 => b := "01111110";
          when others => b := "00000000";
        end case;
      when 'F' =>
        case row is
          when 0 => b := "01111110";
          when 1 => b := "01100000";
          when 2 => b := "01100000";
          when 3 => b := "01111100";
          when 4 => b := "01100000";
          when 5 => b := "01100000";
          when 6 => b := "01100000";
          when others => b := "00000000";
        end case;
      when 'H' =>
        case row is
          when 0 => b := "01100110";
          when 1 => b := "01100110";
          when 2 => b := "01100110";
          when 3 => b := "01111110";
          when 4 => b := "01100110";
          when 5 => b := "01100110";
          when 6 => b := "01100110";
          when others => b := "00000000";
        end case;
      when 'I' =>
        case row is
          when 0 => b := "00111100";
          when 1 => b := "00011000";
          when 2 => b := "00011000";
          when 3 => b := "00011000";
          when 4 => b := "00011000";
          when 5 => b := "00011000";
          when 6 => b := "00111100";
          when others => b := "00000000";
        end case;
      when 'L' =>
        case row is
          when 0 => b := "01100000";
          when 1 => b := "01100000";
          when 2 => b := "01100000";
          when 3 => b := "01100000";
          when 4 => b := "01100000";
          when 5 => b := "01100000";
          when 6 => b := "01111110";
          when others => b := "00000000";
        end case;
      when 'O' =>
        case row is
          when 0 => b := "00111100";
          when 1 => b := "01100110";
          when 2 => b := "01100110";
          when 3 => b := "01100110";
          when 4 => b := "01100110";
          when 5 => b := "01100110";
          when 6 => b := "00111100";
          when others => b := "00000000";
        end case;
      when 'R' =>
        case row is
          when 0 => b := "01111100";
          when 1 => b := "01100110";
          when 2 => b := "01100110";
          when 3 => b := "01111100";
          when 4 => b := "01111000";
          when 5 => b := "01101100";
          when 6 => b := "01100110";
          when others => b := "00000000";
        end case;
      when 'T' =>
        case row is
          when 0 => b := "01111110";
          when 1 => b := "00011000";
          when 2 => b := "00011000";
          when 3 => b := "00011000";
          when 4 => b := "00011000";
          when 5 => b := "00011000";
          when 6 => b := "00011000";
          when others => b := "00000000";
        end case;
      when 'W' =>
        case row is
          when 0 => b := "01100011";
          when 1 => b := "01100011";
          when 2 => b := "01100011";
          when 3 => b := "01101011";
          when 4 => b := "01101011";
          when 5 => b := "01111111";
          when 6 => b := "00110110";
          when others => b := "00000000";
        end case;
      when others =>
        b := "00000000";
    end case;
    return b;
  end function;

  signal r : std_logic_vector(2 downto 0) := (others => '0');
  signal g : std_logic_vector(2 downto 0) := (others => '0');

begin

  -- pixel enable toggles each MCLK
  process(MCLK)
  begin
    if rising_edge(MCLK) then
      pix_ce <= not pix_ce;
    end if;
  end process;

  -- counters and LFSR update ONLY on pix_ce='1'
  process(MCLK)
  begin
    if rising_edge(MCLK) then
      if pix_ce = '1' then
        if h_cnt = to_unsigned(H_TOTAL-1, h_cnt'length) then
          h_cnt <= (others => '0');
          if v_cnt = to_unsigned(V_TOTAL-1, v_cnt'length) then
            v_cnt <= (others => '0');
          else
            v_cnt <= v_cnt + 1;
          end if;
        else
          h_cnt <= h_cnt + 1;
        end if;

        lfsr <= (lfsr(14 downto 0) & (lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10)));
      end if;
    end if;
  end process;

  visible <= '1' when (to_integer(h_cnt) < H_VISIBLE and to_integer(v_cnt) < V_VISIBLE) else '0';

  hs_n <= '0' when (to_integer(h_cnt) >= (H_VISIBLE + H_FP) and
                    to_integer(h_cnt) <  (H_VISIBLE + H_FP + H_SYNC)) else '1';

  vs_n <= '0' when (to_integer(v_cnt) >= (V_VISIBLE + V_FP) and
                    to_integer(v_cnt) <  (V_VISIBLE + V_FP + V_SYNC)) else '1';

  VGA_HS <= hs_n;
  VGA_VS <= vs_n;

  -- pixels computed only on pix_ce (stable between enables)
  process(MCLK)
    variable x, y     : integer;
    variable rain_on  : boolean;
    variable txt_on   : boolean;
    variable msg_i    : integer;
    variable px, py   : integer;
    variable glyph    : std_logic_vector(7 downto 0);
    variable ch       : character;
  begin
    if rising_edge(MCLK) then
      if pix_ce = '1' then
        r <= "000";
        g <= "000";

        if visible = '1' then
          x := to_integer(h_cnt);
          y := to_integer(v_cnt);

          -- matrix dots (power-of-two tests only)
          rain_on := false;
          if h_cnt(2 downto 0) = "000" then
            if std_logic_vector(unsigned(v_cnt(4 downto 0)) + unsigned(lfsr(4 downto 0))) = "00000" then
              rain_on := true;
            end if;
          end if;

          if (not rain_on) then
            if (lfsr(0) = '1') and (h_cnt(5 downto 0) = "000000") and (v_cnt(4 downto 0) = "00000") then
              rain_on := true;
            end if;
          end if;

          if rain_on then
            g <= "010";
          end if;

          -- text overlay
          txt_on := false;
          if (x >= TXT_X) and (x < TXT_X + TXT_W) and (y >= TXT_Y) and (y < TXT_Y + CHAR_H) then
            msg_i := (x - TXT_X) / CHAR_W;
            px    := (x - TXT_X) - (msg_i * CHAR_W);
            py    := (y - TXT_Y);

            ch    := msg_char(msg_i);
            glyph := font8x8(ch, py);

            if glyph(7 - px) = '1' then
              txt_on := true;
            end if;
          end if;

          if txt_on then
            g <= "111";
            r <= "000";
          end if;
        end if;
      end if;
    end if;
  end process;

  VGA_RED   <= r;
  VGA_GREEN <= g;
  VGA_BLUE  <= "00";

end rtl;
