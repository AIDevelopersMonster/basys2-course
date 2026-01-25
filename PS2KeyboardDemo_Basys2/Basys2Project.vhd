-- ============================================================================
-- Basys2 PS/2 keyboard demo (Digilent Basys 2 / Spartan-3E)
--
-- What you should see on the board:
--   * After each key press/release, the last KEY EVENT scan-code byte is latched.
--   * LED[7:0] shows the byte in binary.
--   * 7-seg shows:
--       digit0 = low nibble of code
--       digit1 = high nibble of code
--       digit2 = flags (0 0 E R) where:
--                 E = extended (prefix E0 was seen)
--                 R = release  (prefix F0 was seen)
--       digit3 = errors (0 0 F P) where:
--                 F = frame error (bad start/stop)
--                 P = parity error (odd parity check failed)
--
-- BTN0 clears the latched values.
--
-- Notes:
--   * PS/2 data is sampled on the falling edge of PS2 clock.
--   * This design is input-only: PS2C/PS2D are always driven 'Z' (released).
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ============================================================================
-- Low-level PS/2 receiver: captures 11-bit frames into 8-bit bytes
-- Frame format:
--   start(0) + 8 data bits (LSB first) + odd parity + stop(1)
-- ============================================================================

entity ps2_receiver is
  port (
    clk        : in  std_logic;
    ps2_clk    : in  std_logic;
    ps2_data   : in  std_logic;
    byte_out   : out std_logic_vector(7 downto 0);
    strobe     : out std_logic;
    parity_err : out std_logic;
    frame_err  : out std_logic
  );
end ps2_receiver;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of ps2_receiver is
  -- Synchronizers for asynchronous PS/2 lines
  signal ps2c_sync1, ps2c_sync2 : std_logic := '1';
  signal ps2d_sync1, ps2d_sync2 : std_logic := '1';
  signal ps2c_prev              : std_logic := '1';

  signal bit_count  : integer range 0 to 10 := 0;
  signal start_bit  : std_logic := '1';
  signal parity_bit : std_logic := '1';
  signal data_reg   : std_logic_vector(7 downto 0) := (others => '0');

  function xor_reduce(v : std_logic_vector(7 downto 0)) return std_logic is
    variable x : std_logic := '0';
  begin
    for i in v'range loop
      x := x xor v(i);
    end loop;
    return x;
  end function;
begin
  process(clk)
    variable stop_s    : std_logic;
    variable frame_ok  : boolean;
    variable parity_ok : boolean;
  begin
    if rising_edge(clk) then
      -- Synchronize PS/2 lines into clk domain
      ps2c_sync1 <= ps2_clk;
      ps2c_sync2 <= ps2c_sync1;
      ps2d_sync1 <= ps2_data;
      ps2d_sync2 <= ps2d_sync1;

      -- Default: no new byte this cycle
      strobe <= '0';

      -- Detect falling edge of PS2 clock (data valid on falling edge)
      ps2c_prev <= ps2c_sync2;
      if (ps2c_prev = '1' and ps2c_sync2 = '0') then
        if bit_count = 0 then
          -- Start bit must be 0
          if ps2d_sync2 = '0' then
            start_bit <= '0';
            bit_count <= 1;
          else
            bit_count <= 0; -- wait for real start
          end if;

        elsif bit_count >= 1 and bit_count <= 8 then
          -- Data bits (LSB first).
          -- Shift right: new bit enters MSB, after 8 shifts we have d7..d0 in bits 7..0.
          data_reg  <= ps2d_sync2 & data_reg(7 downto 1);
          bit_count <= bit_count + 1;

        elsif bit_count = 9 then
          parity_bit <= ps2d_sync2;
          bit_count  <= 10;

        else -- bit_count = 10 : stop bit
          stop_s    := ps2d_sync2;
          frame_ok  := (start_bit = '0') and (stop_s = '1');
          parity_ok := (parity_bit = not xor_reduce(data_reg)); -- odd parity

          byte_out <= data_reg;

          if frame_ok then
            frame_err <= '0';
          else
            frame_err <= '1';
          end if;

          if parity_ok then
            parity_err <= '0';
          else
            parity_err <= '1';
          end if;

          strobe <= '1';

          -- Ready for next frame
          bit_count <= 0;
        end if;
      end if;
    end if;
  end process;
end rtl;

-- ============================================================================
-- Keyboard-level parser: filters E0/F0 prefixes and outputs key events
-- ============================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ps2_keyboard is
  port (
    clk          : in  std_logic;
    ps2_clk      : in  std_logic;
    ps2_data     : in  std_logic;
    key_code     : out std_logic_vector(7 downto 0);
    key_strobe   : out std_logic;
    key_release  : out std_logic;
    key_extended : out std_logic;
    parity_err   : out std_logic;
    frame_err    : out std_logic
  );
end ps2_keyboard;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of ps2_keyboard is
  signal rx_byte   : std_logic_vector(7 downto 0);
  signal rx_strobe : std_logic;
  signal rx_perr   : std_logic;
  signal rx_ferr   : std_logic;

  signal ext_pending : std_logic := '0';
  signal rel_pending : std_logic := '0';
begin
  u_rx : entity work.ps2_receiver(rtl)
    port map(
      clk        => clk,
      ps2_clk    => ps2_clk,
      ps2_data   => ps2_data,
      byte_out   => rx_byte,
      strobe     => rx_strobe,
      parity_err => rx_perr,
      frame_err  => rx_ferr
    );

  process(clk)
  begin
    if rising_edge(clk) then
      key_strobe <= '0';

      if rx_strobe = '1' then
        -- propagate errors for this received byte (prefix or key)
        parity_err <= rx_perr;
        frame_err  <= rx_ferr;

        if rx_byte = x"E0" then
          ext_pending <= '1';
        elsif rx_byte = x"F0" then
          rel_pending <= '1';
        else
          key_code     <= rx_byte;
          key_extended <= ext_pending;
          key_release  <= rel_pending;
          key_strobe   <= '1';

          ext_pending <= '0';
          rel_pending <= '0';
        end if;
      end if;
    end if;
  end process;
end rtl;

-- ============================================================================
-- Top-level for the Basys2 template project
-- ============================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Basys2Project is
  port (
    -- Clock inputs
    MCLK      : in    std_logic;

    -- User physical inputs
    BTN       : in    std_logic_vector (3 downto 0);

    -- User LED/Display outputs
    LED       : out   std_logic_vector (7 downto 0);
    SEG       : out   std_logic_vector (6 downto 0);
    AN        : out   std_logic_vector (3 downto 0);


    -- PS2
    PS2C      : inout std_logic;
    PS2D      : inout std_logic
   
  );
end Basys2Project;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of Basys2Project is
  -- 7-seg helper: returns active-low pattern in order (6..0) = CG..CA
  function hex_to_7seg(n : std_logic_vector(3 downto 0)) return std_logic_vector is
    variable s : std_logic_vector(6 downto 0);
  begin
    case n is
      when "0000" => s := "1000000"; -- 0
      when "0001" => s := "1111001"; -- 1
      when "0010" => s := "0100100"; -- 2
      when "0011" => s := "0110000"; -- 3
      when "0100" => s := "0011001"; -- 4
      when "0101" => s := "0010010"; -- 5
      when "0110" => s := "0000010"; -- 6
      when "0111" => s := "1111000"; -- 7
      when "1000" => s := "0000000"; -- 8
      when "1001" => s := "0010000"; -- 9
      when "1010" => s := "0001000"; -- A
      when "1011" => s := "0000011"; -- b
      when "1100" => s := "1000110"; -- C
      when "1101" => s := "0100001"; -- d
      when "1110" => s := "0000110"; -- E
      when others => s := "0001110"; -- F
    end case;
    return s;
  end function;

  -- PS/2 physical inputs (we drive Z, keyboard drives low, pullups make idle high)
  signal ps2c_in, ps2d_in : std_logic;

  -- Decoded key events
  signal key_code     : std_logic_vector(7 downto 0);
  signal key_strobe   : std_logic;
  signal key_release  : std_logic;
  signal key_extended : std_logic;
  signal rx_perr      : std_logic;
  signal rx_ferr      : std_logic;

  -- Latched display registers (updated on key_strobe)
  signal code_reg : std_logic_vector(7 downto 0) := (others => '0');
  signal rel_reg  : std_logic := '0';
  signal ext_reg  : std_logic := '0';
  signal perr_reg : std_logic := '0';
  signal ferr_reg : std_logic := '0';

  -- 7-seg scan
  signal refresh_cnt : unsigned(15 downto 0) := (others => '0');
  signal digit_sel   : std_logic_vector(1 downto 0);

  signal seg0, seg1, seg2, seg3 : std_logic_vector(6 downto 0);
  signal seg_next               : std_logic_vector(6 downto 0);
  signal an_next                : std_logic_vector(3 downto 0);
begin
  -- Always release PS/2 lines (input-only design)
  PS2C <= 'Z';
  PS2D <= 'Z';
  ps2c_in <= PS2C;
  ps2d_in <= PS2D;



  -- PS/2 keyboard front-end
  u_kbd : entity work.ps2_keyboard(rtl)
    port map(
      clk          => MCLK,
      ps2_clk      => ps2c_in,
      ps2_data     => ps2d_in,
      key_code     => key_code,
      key_strobe   => key_strobe,
      key_release  => key_release,
      key_extended => key_extended,
      parity_err   => rx_perr,
      frame_err    => rx_ferr
    );

  -- Latch last key event (BTN0 clears)
  process(MCLK)
  begin
    if rising_edge(MCLK) then
      if BTN(0) = '1' then
        code_reg <= (others => '0');
        rel_reg  <= '0';
        ext_reg  <= '0';
        perr_reg <= '0';
        ferr_reg <= '0';
      elsif key_strobe = '1' then
        code_reg <= key_code;
        rel_reg  <= key_release;
        ext_reg  <= key_extended;
        perr_reg <= rx_perr;
        ferr_reg <= rx_ferr;
      end if;
    end if;
  end process;

  -- LEDs show last key byte
  LED <= code_reg;

  -- 7-seg contents (hex):
  --   digit0: low nibble of code
  --   digit1: high nibble of code
  --   digit2: 0 0 E R
  --   digit3: 0 0 F P
  seg0 <= hex_to_7seg(code_reg(3 downto 0));
  seg1 <= hex_to_7seg(code_reg(7 downto 4));
  seg2 <= hex_to_7seg("00" & ext_reg & rel_reg);
  seg3 <= hex_to_7seg("00" & ferr_reg & perr_reg);

  -- 7-seg multiplexing: use upper bits of a free-running counter
  process(MCLK)
  begin
    if rising_edge(MCLK) then
      refresh_cnt <= refresh_cnt + 1;
    end if;
  end process;

  digit_sel <= std_logic_vector(refresh_cnt(15 downto 14));

  process(digit_sel, seg0, seg1, seg2, seg3)
  begin
    case digit_sel is
      when "00" =>
        an_next  <= "1110"; -- enable AN0
        seg_next <= seg0;
      when "01" =>
        an_next  <= "1101"; -- AN1
        seg_next <= seg1;
      when "10" =>
        an_next  <= "1011"; -- AN2
        seg_next <= seg2;
      when others =>
        an_next  <= "0111"; -- AN3
        seg_next <= seg3;
    end case;
  end process;

  AN  <= an_next;
  SEG <= seg_next;
 
end rtl;
