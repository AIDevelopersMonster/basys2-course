-- =============================================================================
-- Project : Basys2 Course / P17
-- File    : P17_Counter_8bit_7seg.vhd
-- Title   : 8-bit Counter + Clock Divider + 7-seg (HEX/DEC)
-- Board   : Digilent Basys 2 (Spartan-3E XC3S100E)
-- Tool    : Xilinx ISE (XST)
-- Language: VHDL
-- =============================================================================
--
-- Описание
-- --------
-- Учебный проект P17 реализует 8-битный счётчик (0..255) с делителем тактовой
-- частоты (примерно 1 Гц) и выводом значения:
--   • LED[7:0]  - двоичное значение счётчика
--   • 7-seg     - отображение значения в HEX или DEC (по переключателю)
--
-- Цель проекта
-- ------------
-- 1) Показать принцип делителя частоты (Clock Divider) от системного MCLK
-- 2) Закрепить работу с регистрами состояния (счётчик как регистр)
-- 3) Реализовать "человеческую" индикацию на 7-seg в HEX и DEC форматах
-- 4) Для DEC режима применить bin→BCD (Double Dabble), без операций деления,
--    т.к. XST не синтезирует деление переменной на 10/100.
--
-- Управление (переключатели и кнопки)
-- ----------------------------------
-- SW[7]  : режим счёта
--          0 - AUTO (счёт по тик-импульсу ~1 Гц)
--          1 - STEP (счёт по кнопке BTN1)
-- SW[6]  : формат вывода на 7-seg
--          0 - HEX  (H0xx)
--          1 - DEC  (dXYZ)
-- SW[7:0]: данные для загрузки значения счётчика (LOAD)
--
-- BTN0   : RESET  -> count := 0
-- BTN1   : STEP   -> count := count + 1 (только в режиме STEP, SW7=1)
-- BTN2   : HOLD   -> пауза/продолжение (только в режиме AUTO, SW7=0)
-- BTN3   : LOAD   -> count := SW[7:0]
--
-- Индикация 7-seg
-- --------------
-- Режим HEX (SW6=0):  [DIG3][DIG2][DIG1][DIG0] =  H  0  hi lo
-- Режим DEC (SW6=1):  [DIG3][DIG2][DIG1][DIG0] =  d  hundreds tens ones
--
-- Примечания по аппаратной части
-- ------------------------------
-- 1) AN и SEG считаются active-low (0 включает разряд/сегмент).
-- 2) Порядок сегментов: SEG(0)=CA ... SEG(6)=CG, SEG(7)=DP.
-- 3) Частота MCLK на Basys2 может быть 25/50/100 МГц (перемычка JP4).
--    В коде используется константа CLK_HZ. Если "1 Гц" не совпадает по
--    скорости - измените CLK_HZ на реальное значение.
--
-- Проверка на плате (быстро)
-- --------------------------
-- 1) AUTO: SW7=0, SW6=0 -> счёт на LED и 7-seg растёт ~1 раз/сек.
-- 2) HOLD: нажать BTN2 -> остановить, ещё раз BTN2 -> продолжить.
-- 3) STEP: SW7=1 -> каждое нажатие BTN1 увеличивает значение на 1.
-- 4) LOAD: выставить SW=00110011, нажать BTN3 -> значение станет 0x33 (51).
--          HEX: H033, DEC: d051.
--
-- =============================================================================


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity P17_Counter_8bit_7seg is
  port (
    MCLK : in  std_logic;
    SW   : in  std_logic_vector(7 downto 0);
    BTN  : in  std_logic_vector(3 downto 0);

    LED  : out std_logic_vector(7 downto 0);

    AN   : out std_logic_vector(3 downto 0);  -- active-low
    SEG  : out std_logic_vector(7 downto 0)   -- SEG(0)=CA..SEG(6)=CG, SEG(7)=DP active-low
  );
end P17_Counter_8bit_7seg;

architecture Behavioral of P17_Counter_8bit_7seg is

  ---------------------------------------------------------------------------
  -- Настройка частоты
  -- Basys2 может быть 25/50/100 MHz (перемычка JP4).
  -- Если "1 Гц" не совпадает - поменяй CLK_HZ.
  ---------------------------------------------------------------------------
  constant CLK_HZ  : integer := 50000000; -- 25000000 или 100000000 при необходимости
  constant TICK_HZ : integer := 1;
  constant DIV_MAX : integer := (CLK_HZ / TICK_HZ) - 1;

  ---------------------------------------------------------------------------
  -- Debounce + pulse (anti-bounce + one-shot)
  ---------------------------------------------------------------------------
  signal btn_sync0, btn_sync1 : std_logic_vector(3 downto 0) := (others => '0');
  signal btn_stable, btn_prev : std_logic_vector(3 downto 0) := (others => '0');
  signal btn_pulse            : std_logic_vector(3 downto 0) := (others => '0');

  type t_cnt_arr is array (0 to 3) of integer range 0 to 250000; -- ~5ms @50MHz
  signal db_cnt : t_cnt_arr := (others => 0);

  ---------------------------------------------------------------------------
  -- Divider tick ~1 Hz
  ---------------------------------------------------------------------------
  signal div_cnt  : integer range 0 to DIV_MAX := 0;
  signal tick_1hz : std_logic := '0';

  ---------------------------------------------------------------------------
  -- Counter + control
  ---------------------------------------------------------------------------
  signal count : unsigned(7 downto 0) := (others => '0');
  signal hold  : std_logic := '0';

  ---------------------------------------------------------------------------
  -- 7-seg scan
  ---------------------------------------------------------------------------
  signal scan_cnt  : unsigned(15 downto 0) := (others => '0');
  signal digit_sel : unsigned(1 downto 0)  := (others => '0');

  -- digits with DP (active-low)
  signal s0, s1, s2, s3 : std_logic_vector(7 downto 0) := (others => '1');

  -- DEC digits (BCD)
  signal hundreds, tens, ones : unsigned(3 downto 0) := (others => '0');

  ---------------------------------------------------------------------------
  -- HEX->7SEG (active-low), order: SEG(0)=CA..SEG(6)=CG, SEG(7)=DP
  -- DP в этой функции = 1 (выкл), DP назначаем отдельно
  ---------------------------------------------------------------------------
  function hex7seg_active_low(h : std_logic_vector(3 downto 0)) return std_logic_vector is
    variable s : std_logic_vector(7 downto 0);
  begin
    -- DP  g   f   e   d   c   b   a   (но вектор: [7]=DP, [6]=CG ... [0]=CA)
    -- Для принятого порядка SEG(0)=CA..SEG(6)=CG, SEG(7)=DP:
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

  -- символ 'H' (приближённо) и 'd'
  function charH return std_logic_vector is
    variable s : std_logic_vector(7 downto 0);
  begin
    -- H: b,c,e,f,g (без a,d) + DP=1
    -- Для активного нуля: 0 = горит сегмент
    -- a b c d e f g dp  (как идея), но у нас порядок другой; используем готовый образ:
    -- Этот шаблон обычно даёт читаемую 'H' на Basys2; если захочешь - подстроим.
    s := "10001001"; -- как в прошлых проектах (active-low)
    return s;
  end function;

  function chard return std_logic_vector is
  begin
    return "10100001"; -- 'd' (как в таблице)
  end function;

begin

  ---------------------------------------------------------------------------
  -- Button sync
  ---------------------------------------------------------------------------
  process(MCLK)
  begin
    if rising_edge(MCLK) then
      btn_sync0 <= BTN;
      btn_sync1 <= btn_sync0;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Debounce + pulse on press
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
  -- Divider: 1 Hz tick
  ---------------------------------------------------------------------------
  process(MCLK)
  begin
    if rising_edge(MCLK) then
      if div_cnt = DIV_MAX then
        div_cnt  <= 0;
        tick_1hz <= '1';
      else
        div_cnt  <= div_cnt + 1;
        tick_1hz <= '0';
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Counter control
  -- SW7: 0=AUTO, 1=STEP
  -- SW6: 0=HEX,  1=DEC (only display)
  -- BTN0 RESET, BTN1 STEP, BTN2 HOLD toggle, BTN3 LOAD
  ---------------------------------------------------------------------------
  process(MCLK)
  begin
    if rising_edge(MCLK) then

      -- RESET
      if btn_pulse(0) = '1' then
        count <= (others => '0');
      end if;

      -- LOAD SW->count
      if btn_pulse(3) = '1' then
        count <= unsigned(SW);
      end if;

      -- HOLD toggle (useful in AUTO)
      if btn_pulse(2) = '1' then
        hold <= not hold;
      end if;

      if SW(7) = '1' then
        -- STEP mode
        if btn_pulse(1) = '1' then
          count <= count + 1;
        end if;
      else
        -- AUTO mode
        if (tick_1hz = '1') and (hold = '0') then
          count <= count + 1;
        end if;
      end if;

    end if;
  end process;

  ---------------------------------------------------------------------------
  -- LED: binary value
  ---------------------------------------------------------------------------
  LED <= std_logic_vector(count);

  ---------------------------------------------------------------------------
  -- BIN->BCD (0..255) using Double Dabble (no division, synthesizable in XST)
  ---------------------------------------------------------------------------
  process(count)
    variable bcd : unsigned(11 downto 0); -- [hundreds|tens|ones]
    variable bin : unsigned(7 downto 0);
  begin
    bcd := (others => '0');
    bin := count;

    for i in 0 to 7 loop
      if bcd(3 downto 0) > 4 then
        bcd(3 downto 0) := bcd(3 downto 0) + 3;
      end if;
      if bcd(7 downto 4) > 4 then
        bcd(7 downto 4) := bcd(7 downto 4) + 3;
      end if;
      if bcd(11 downto 8) > 4 then
        bcd(11 downto 8) := bcd(11 downto 8) + 3;
      end if;

      bcd := bcd(10 downto 0) & bin(7);
      bin := bin(6 downto 0) & '0';
    end loop;

    ones     <= bcd(3 downto 0);
    tens     <= bcd(7 downto 4);
    hundreds <= bcd(11 downto 8);
  end process;

  ---------------------------------------------------------------------------
  -- Prepare 7-seg digits
  -- HEX: [H][0][hi][lo]
  -- DEC: [d][hundreds][tens][ones]
  ---------------------------------------------------------------------------
  process(SW, count, hundreds, tens, ones)
    variable hi, lo : std_logic_vector(3 downto 0);
  begin
    hi := std_logic_vector(count(7 downto 4));
    lo := std_logic_vector(count(3 downto 0));

    if SW(6) = '0' then
      -- HEX
      s3 <= charH;                          s3(7) <= '1';
      s2 <= hex7seg_active_low("0000");     s2(7) <= '1';
      s1 <= hex7seg_active_low(hi);         s1(7) <= '1';
      s0 <= hex7seg_active_low(lo);         s0(7) <= '1';
    else
      -- DEC
      s3 <= chard;                          s3(7) <= '1';
      s2 <= hex7seg_active_low(std_logic_vector(hundreds)); s2(7) <= '1';
      s1 <= hex7seg_active_low(std_logic_vector(tens));     s1(7) <= '1';
      s0 <= hex7seg_active_low(std_logic_vector(ones));     s0(7) <= '1';
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- 7-seg scanning
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
