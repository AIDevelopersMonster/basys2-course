--#############################################################################
--# P19_Serial_Adder_tb.vhd
--#
--# Тестбенч для P19_Serial_Adder.
--# Особенности:
--#   - Инициализация всех сигналов (без U/X на старте)
--#   - Нажатия кнопок моделируются короткими импульсами
--#   - Проверка результата для нескольких наборов (assert)
--#############################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity P19_Serial_Adder_tb is
end entity;

architecture TB of P19_Serial_Adder_tb is

  constant TCLK : time := 20 ns; -- 50 MHz

  signal MCLK : std_logic := '0';
  signal BTN  : std_logic_vector(3 downto 0) := (others => '0');
  signal SW   : std_logic_vector(7 downto 0) := (others => '0');
  signal LED  : std_logic_vector(7 downto 0);

  -- удобные функции
  function to_slv4(n : natural) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(n, 4));
  end function;

  procedure pulse_btn(signal b : inout std_logic; width : time) is
  begin
    b <= '1';
    wait for width;
    b <= '0';
  end procedure;

  -- ВАЖНО: сигналы, в которые пишем, должны быть формальными signal-параметрами процедуры.
  procedure do_case(
    signal SW_s  : inout std_logic_vector(7 downto 0);
    signal BTN_s : inout std_logic_vector(3 downto 0);
    signal LED_s : in    std_logic_vector(7 downto 0);
    a : natural;
    b : natural
  ) is
    variable sum  : natural;
    variable cout : natural;
    variable cout_sl : std_logic;
  begin
    -- подать A,B на SW
    SW_s(3 downto 0) <= to_slv4(a);
    SW_s(7 downto 4) <= to_slv4(b);

    -- LOAD/RESET (BTN3)
    wait for 5*TCLK;
    pulse_btn(BTN_s(3), 200 ns);

    -- 4 шага STEP (BTN0)
    -- (в симуляции debounce укорочен generic'ом)
    wait for 5*TCLK;
    pulse_btn(BTN_s(0), 200 ns); wait for 2 us;
    pulse_btn(BTN_s(0), 200 ns); wait for 2 us;
    pulse_btn(BTN_s(0), 200 ns); wait for 2 us;
    pulse_btn(BTN_s(0), 200 ns); wait for 2 us;

    -- ожидание стабилизации
    wait for 20*TCLK;

    sum  := (a + b) mod 16;
    cout := (a + b) / 16;
    if cout = 1 then
      cout_sl := '1';
    else
      cout_sl := '0';
    end if;

    assert LED_s(3 downto 0) = to_slv4(sum)
      report "SUM mismatch. A=" & integer'image(a) &
             " B=" & integer'image(b) &
             " expected SUM=" & integer'image(sum)
      severity error;

    assert LED_s(4) = cout_sl
      report "COUT mismatch. A=" & integer'image(a) &
             " B=" & integer'image(b) &
             " expected COUT=" & integer'image(cout)
      severity error;
  end procedure;

begin

  -- DUT
  dut: entity work.P19_Serial_Adder
    generic map(
      -- чтобы симуляция не длилась десятки миллисекунд на каждый клик
      G_DEBOUNCE_CYCLES => 10
    )
    port map(
      MCLK => MCLK,
      BTN  => BTN,
      SW   => SW,
      LED  => LED
    );

  -- clock
  clk_gen: process
  begin
    while true loop
      MCLK <= '0'; wait for TCLK/2;
      MCLK <= '1'; wait for TCLK/2;
    end loop;
  end process;

  -- tests
  stim: process
  begin
    -- начальная инициализация
    BTN <= (others => '0');
    SW  <= (others => '0');
    wait for 200 ns;

    -- несколько проверок
    do_case(SW, BTN, LED, 0, 0);
    do_case(SW, BTN, LED, 3, 5);
    do_case(SW, BTN, LED, 9, 7);
    do_case(SW, BTN, LED, 15, 1);
    do_case(SW, BTN, LED, 15, 15);

    report "All testcases passed." severity note;
    wait;
  end process;

end architecture;