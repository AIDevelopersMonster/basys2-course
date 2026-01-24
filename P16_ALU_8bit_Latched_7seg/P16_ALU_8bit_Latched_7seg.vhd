library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity P16_ALU_8bit_Latched_7seg is
  port (
    MCLK : in  std_logic;
    SW   : in  std_logic_vector(7 downto 0);
    BTN  : in  std_logic_vector(3 downto 0);

    LED  : out std_logic_vector(7 downto 0);

    AN   : out std_logic_vector(3 downto 0);  -- active-low
    SEG  : out std_logic_vector(7 downto 0)   -- CA..CG,DP active-low
  );
end P16_ALU_8bit_Latched_7seg;

architecture Behavioral of P16_ALU_8bit_Latched_7seg is

  -- Регистры
  signal A_reg  : std_logic_vector(7 downto 0) := (others => '0');
  signal B_reg  : std_logic_vector(7 downto 0) := (others => '0');
  signal OP_reg : std_logic_vector(2 downto 0) := (others => '0');
  signal F_reg  : std_logic_vector(7 downto 0) := (others => '0');

  signal done   : std_logic := '0';
  signal ovf    : std_logic := '0';

  -- Что показываем на LED
  type t_view is (VIEW_SW, VIEW_A, VIEW_B, VIEW_OP);
  signal view : t_view := VIEW_SW;
  signal led_value : std_logic_vector(7 downto 0) := (others => '0');

  -- Debounce + pulse
  signal btn_sync0, btn_sync1 : std_logic_vector(3 downto 0) := (others => '0');
  signal btn_stable, btn_prev : std_logic_vector(3 downto 0) := (others => '0');
  signal btn_pulse            : std_logic_vector(3 downto 0) := (others => '0');

  type t_cnt_arr is array (0 to 3) of integer range 0 to 250000; -- ~5ms @50MHz
  signal db_cnt : t_cnt_arr := (others => 0);

  -- 7-seg scan
  signal scan_cnt  : unsigned(15 downto 0) := (others => '0');
  signal digit_sel : unsigned(1 downto 0)  := (others => '0');

  -- "Цифры" (active-low), без DP
  signal d0, d1, d2, d3 : std_logic_vector(7 downto 0) := (others => '1');
  -- "Цифры" с DP
  signal s0, s1, s2, s3 : std_logic_vector(7 downto 0) := (others => '1');

  -- signed представление
  signal A_s, B_s : signed(7 downto 0);

  ---------------------------------------------------------------------------
  -- Функция HEX->7SEG (active-low). DP здесь = 1 (выкл)
  ---------------------------------------------------------------------------
  -- SEG(0)=CA ... SEG(6)=CG, SEG(7)=DP, active-low
function hex7seg_active_low(h : std_logic_vector(3 downto 0)) return std_logic_vector is
  --           DP  CG  CF  CE  CD  CC  CB  CA
  -- index:     7   6   5   4   3   2   1   0
  variable s : std_logic_vector(7 downto 0);
begin
  case h is
    when "0000" => s := "11000000"; -- 0
    when "0001" => s := "11111001"; -- 1
    when "0010" => s := "10100100"; -- 2
    when "0011" => s := "10110000"; -- 3
    when "0100" => s := "10011001"; -- 4
    when "0101" => s := "10010010"; -- 5
    when "0110" => s := "10000010"; -- 6
    when "0111" => s := "11111000"; -- 7
    when "1000" => s := "10000000"; -- 8
    when "1001" => s := "10010000"; -- 9
    when "1010" => s := "10001000"; -- A
    when "1011" => s := "10000011"; -- b
    when "1100" => s := "11000110"; -- C
    when "1101" => s := "10100001"; -- d
    when "1110" => s := "10000110"; -- E
    when others => s := "10001110"; -- F
  end case;
  return s;
end function;

begin

  A_s <= signed(A_reg);
  B_s <= signed(B_reg);

  ---------------------------------------------------------------------------
  -- 1) Синхронизация кнопок
  ---------------------------------------------------------------------------
  process(MCLK)
  begin
    if rising_edge(MCLK) then
      btn_sync0 <= BTN;
      btn_sync1 <= btn_sync0;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- 2) Debounce + pulse на нажатие
  ---------------------------------------------------------------------------
  process(MCLK)
  begin
    if rising_edge(MCLK) then
      btn_pulse <= (others => '0');

      for i in 0 to 3 loop
        if btn_sync1(i) = btn_stable(i) then
          db_cnt(i) <= 0;
        else
          if db_cnt(i) = 250000 then
            btn_stable(i) <= btn_sync1(i);
            db_cnt(i) <= 0;
          else
            db_cnt(i) <= db_cnt(i) + 1;
          end if;
        end if;
      end loop;

      for i in 0 to 3 loop
        if (btn_prev(i) = '0') and (btn_stable(i) = '1') then
          btn_pulse(i) <= '1';
        end if;
      end loop;

      btn_prev <= btn_stable;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- 3) Захват A/B/OP и EXEC
  -- OP берём из SW(2 downto 0) (удобно)
  ---------------------------------------------------------------------------
  process(MCLK)
    variable tmp9 : signed(8 downto 0);
    variable res8 : signed(7 downto 0);
    variable ov   : std_logic;
  begin
    if rising_edge(MCLK) then

      if btn_pulse(0) = '1' then
        A_reg <= SW;
        view  <= VIEW_A;
        done  <= '0';
      end if;

      if btn_pulse(1) = '1' then
        B_reg <= SW;
        view  <= VIEW_B;
        done  <= '0';
      end if;

      if btn_pulse(2) = '1' then
        OP_reg <= SW(2 downto 0);
        view   <= VIEW_OP;
        done   <= '0';
      end if;

      if btn_pulse(3) = '1' then
        ov   := '0';
        tmp9 := (others => '0');
        res8 := (others => '0');

        case OP_reg is
          when "000" => -- A + B
            tmp9 := resize(A_s, 9) + resize(B_s, 9);
            res8 := signed(tmp9(7 downto 0));
            if (A_s(7) = B_s(7)) and (res8(7) /= A_s(7)) then ov := '1'; end if;

          when "001" => -- A + 1
            tmp9 := resize(A_s, 9) + to_signed(1, 9);
            res8 := signed(tmp9(7 downto 0));
            if (A_s(7) = '0') and (res8(7) = '1') then ov := '1'; end if;
            if (A_s(7) = '1') and (res8(7) = '0') then ov := '1'; end if;

          when "010" => -- A - B
            tmp9 := resize(A_s, 9) - resize(B_s, 9);
            res8 := signed(tmp9(7 downto 0));
            if (A_s(7) /= B_s(7)) and (res8(7) /= A_s(7)) then ov := '1'; end if;

          when "011" => -- XOR
            res8 := signed(std_logic_vector(A_reg xor B_reg));

          when "100" => -- OR
            res8 := signed(std_logic_vector(A_reg or B_reg));

          when "101" => -- AND
            res8 := signed(std_logic_vector(A_reg and B_reg));

          when others =>
            res8 := (others => '0');
        end case;

        F_reg <= std_logic_vector(res8);
        ovf   <= ov;
        done  <= '1';
        view  <= VIEW_SW;
      end if;

      if (btn_pulse = "0000") then
        view <= VIEW_SW;
      end if;

    end if;
  end process;

  ---------------------------------------------------------------------------
  -- 4) LED: что сейчас "на экране"
  ---------------------------------------------------------------------------
  process(view, SW, A_reg, B_reg, OP_reg)
  begin
    case view is
      when VIEW_SW => led_value <= SW;
      when VIEW_A  => led_value <= A_reg;
      when VIEW_B  => led_value <= B_reg;
      when VIEW_OP => led_value <= "00000" & OP_reg;
    end case;
  end process;

  LED <= led_value;

  ---------------------------------------------------------------------------
  -- 5) 7-seg:  [DIG3]=F, [DIG2]=OP, [DIG1]=F_hi, [DIG0]=F_lo
  -- DP(DIG3)=DONE, DP(DIG2)=OVF
  ---------------------------------------------------------------------------
  d3 <= hex7seg_active_low("1111");          -- F
  d2 <= hex7seg_active_low('0' & OP_reg);    -- OP 0..7
  d1 <= hex7seg_active_low(F_reg(7 downto 4));
  d0 <= hex7seg_active_low(F_reg(3 downto 0));

  -- добавляем DP (active-low: 0=горит)
  process(d0, d1, d2, d3, done, ovf)
  begin
    s0 <= d0; s0(7) <= '1';
    s1 <= d1; s1(7) <= '1';
    s2 <= d2; s2(7) <= not ovf;   -- ovf=1 => dp=0
    s3 <= d3; s3(7) <= not done;  -- done=1 => dp=0
  end process;

  ---------------------------------------------------------------------------
  -- 6) Сканирование 7-seg
  ---------------------------------------------------------------------------
  process(MCLK)
  begin
    if rising_edge(MCLK) then
      scan_cnt  <= scan_cnt + 1;
      digit_sel <= scan_cnt(15 downto 14);
    end if;
  end process;

  process(digit_sel, s0, s1, s2, s3)
  begin
    case digit_sel is
      when "00" =>
        AN  <= "1110"; -- DIG0
        SEG <= s0;
      when "01" =>
        AN  <= "1101"; -- DIG1
        SEG <= s1;
      when "10" =>
        AN  <= "1011"; -- DIG2
        SEG <= s2;
      when others =>
        AN  <= "0111"; -- DIG3
        SEG <= s3;
    end case;
  end process;

end Behavioral;
