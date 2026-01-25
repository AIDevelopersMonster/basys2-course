--#############################################################################
--# P19_Serial_Adder.vhd
--#
--# Последовательный сумматор (Serial Adder) для Digilent Basys 2 (Spartan-3E).
--#
--# Идея:
--#   На каждом шаге (STEP) складывается младший бит регистров A и B с переносом
--#   carry. Полученный бит суммы записывается в позицию bit_idx результата.
--#   Затем A и B сдвигаются вправо, carry обновляется, bit_idx увеличивается.
--#   После N шагов (N=4) флаг done=1 и на LED4 выводится итоговый перенос.
--#
--# Управление (по умолчанию):
--#   SW(3 downto 0)  -> A[3:0]
--#   SW(7 downto 4)  -> B[3:0]
--#   BTN3            -> LOAD/RESET (загрузить A,B и сбросить вычисление)
--#   BTN0            -> STEP (один шаг сложения; есть программная блокировка дребезга)
--#
--# Индикация:
--#   LED(3 downto 0) -> SUM[3:0]
--#   LED4            -> COUT (горит только после завершения, done=1)
--#   LED(7 downto 5) -> bit_idx (0..3)
--#############################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity P19_Serial_Adder is
  generic (
    -- Кол-во тактов блокировки после нажатия STEP (антидребезг/anti-repeat).
    -- Для платы (50 MHz) удобно ~20 мс: 1_000_000 тактов.
    -- Для симуляции можно поставить значительно меньше (см. testbench).
    G_DEBOUNCE_CYCLES : natural := 1_000_000
  );
  port (
    MCLK : in  std_logic;                     -- системный такт (Basys 2: 50 MHz)
    BTN  : in  std_logic_vector(3 downto 0);   -- кнопки
    SW   : in  std_logic_vector(7 downto 0);   -- тумблеры
    LED  : out std_logic_vector(7 downto 0)    -- светодиоды
  );
end P19_Serial_Adder;

architecture RTL of P19_Serial_Adder is
  constant N : integer := 4;

  signal a_reg   : std_logic_vector(N-1 downto 0) := (others => '0');
  signal b_reg   : std_logic_vector(N-1 downto 0) := (others => '0');
  signal sum_reg : std_logic_vector(N-1 downto 0) := (others => '0');

  signal carry   : std_logic := '0';
  signal bit_idx : unsigned(2 downto 0) := (others => '0');
  signal done    : std_logic := '0';

  -- синхронизация кнопок (двухтактная)
  signal btn0_ff1, btn0_ff2 : std_logic := '0';
  signal btn3_ff1, btn3_ff2 : std_logic := '0';

  -- программная блокировка дребезга для STEP
  signal step_lock  : unsigned(19 downto 0) := (others => '0');
  signal step_pulse : std_logic := '0';

  -- фронты (после синхронизации)
  signal step_rise : std_logic := '0';
  signal load_rise : std_logic := '0';

begin

  -----------------------------------------------------------------------------
  -- 1) Синхронизация асинхронных кнопок в домен MCLK
  -----------------------------------------------------------------------------
  process(MCLK)
  begin
    if rising_edge(MCLK) then
      btn0_ff1 <= BTN(0);
      btn0_ff2 <= btn0_ff1;

      btn3_ff1 <= BTN(3);
      btn3_ff2 <= btn3_ff1;
    end if;
  end process;

  -- Детект фронта (0->1) после синхронизации
  step_rise <= '1' when (btn0_ff2 = '0' and btn0_ff1 = '1') else '0';
  load_rise <= '1' when (btn3_ff2 = '0' and btn3_ff1 = '1') else '0';

  -----------------------------------------------------------------------------
  -- 2) Формирование одиночного STEP-импульса с блокировкой дребезга
  --    Идея простая: после зарегистрированного нажатия игнорируем кнопку
  --    примерно 20 мс (для 50 МГц ~ 1_000_000 тактов).
  -----------------------------------------------------------------------------
  process(MCLK)
  begin
    if rising_edge(MCLK) then
      step_pulse <= '0';

      if step_lock /= 0 then
        step_lock <= step_lock - 1;
      else
        if step_rise = '1' then
          step_pulse <= '1';
          step_lock  <= to_unsigned(G_DEBOUNCE_CYCLES, step_lock'length);
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- 3) Последовательное сложение (по шагу)
  -----------------------------------------------------------------------------
  process(MCLK)
    variable s   : std_logic;
    variable c_n : std_logic;
    variable idx : integer;
  begin
    if rising_edge(MCLK) then
      if load_rise = '1' then
        -- загрузка операндов и сброс состояния
        a_reg   <= SW(3 downto 0);
        b_reg   <= SW(7 downto 4);
        sum_reg <= (others => '0');
        carry   <= '0';
        bit_idx <= (others => '0');
        done    <= '0';

      elsif step_pulse = '1' then
        if done = '0' then
          -- полный сумматор: s = a xor b xor carry
          s   := a_reg(0) xor b_reg(0) xor carry;
          c_n := (a_reg(0) and b_reg(0)) or (a_reg(0) and carry) or (b_reg(0) and carry);

          idx := to_integer(bit_idx);
          if idx >= 0 and idx < N then
            sum_reg(idx) <= s;
          end if;

          -- сдвиги операндов
          a_reg <= '0' & a_reg(N-1 downto 1);
          b_reg <= '0' & b_reg(N-1 downto 1);

          carry <= c_n;

          if bit_idx = to_unsigned(N-1, bit_idx'length) then
            done <= '1';
          else
            bit_idx <= bit_idx + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- 4) Индикация
  -----------------------------------------------------------------------------
  LED(3 downto 0) <= sum_reg;
  LED(4)          <= carry when done = '1' else '0';
  LED(7 downto 5) <= std_logic_vector(bit_idx);

end RTL;