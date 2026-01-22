library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_P10_Simulate_SR_Latch is
end tb_P10_Simulate_SR_Latch;

architecture TB of tb_P10_Simulate_SR_Latch is
  signal S_n, R_n : std_logic := '1';

  signal Q_bal, Qb_bal : std_logic;
  signal Q_bias, Qb_bias : std_logic;

  -- для "симметричного" варианта (чаще показывает колебания/неопределенность)
  constant TQ_BAL  : time := 1 ns;
  constant TQB_BAL : time := 1 ns;

  -- для "несимметричного" (обычно быстрее "выбирает" одно устойчивое состояние)
  constant TQ_BIAS  : time := 1 ns;
  constant TQB_BIAS : time := 2 ns;

  -- счётчик переключений Q_bal после 600 ns
  signal toggles_q_bal : integer := 0;
begin

  -- DUT 1: balanced delays (more prone to astable/metastable-like behavior)
  U_BAL: entity work.sr_latch_nand
    generic map (
      SIM  => true,
      T_Q  => TQ_BAL,
      T_QB => TQB_BAL
    )
    port map (
      S_n => S_n,
      R_n => R_n,
      Q   => Q_bal,
      Qb  => Qb_bal
    );

  -- DUT 2: biased delays (break symmetry)
  U_BIAS: entity work.sr_latch_nand
    generic map (
      SIM  => true,
      T_Q  => TQ_BIAS,
      T_QB => TQB_BIAS
    )
    port map (
      S_n => S_n,
      R_n => R_n,
      Q   => Q_bias,
      Qb  => Qb_bias
    );

  -- Стимулы
  stim: process
  begin
    -- 0 ns: hold
    S_n <= '1'; R_n <= '1';
    wait for 100 ns;

    -- SET: S_n=0, R_n=1  => Q=1, Qb=0
    S_n <= '0'; R_n <= '1';
    wait for 100 ns;

    -- hold
    S_n <= '1'; R_n <= '1';
    wait for 100 ns;

    -- RESET: S_n=1, R_n=0 => Q=0, Qb=1
    S_n <= '1'; R_n <= '0';
    wait for 100 ns;

    -- hold
    S_n <= '1'; R_n <= '1';
    wait for 100 ns;

    -- forbidden: both asserted (active-low) => Q=Qb=1 (confounded)
    S_n <= '0'; R_n <= '0';
    wait for 100 ns;

    -- 600 ns: both toggle 0 -> 1 simultaneously (enter hold from forbidden)
    -- This is the classic trigger for unstable/metastable-like behavior. :contentReference[oaicite:3]{index=3}
    S_n <= '1'; R_n <= '1';
    wait for 200 ns;

    report "TB DONE: check waveform around 600 ns for instability/glitching." severity note;
    wait;
  end process;

  -- Считаем переключения Q_bal в окне после 600 ns (для подсказки в консоли)
  count_toggles: process(Q_bal)
  begin
    if now >= 600 ns and now <= 750 ns then
      toggles_q_bal <= toggles_q_bal + 1;
    end if;
  end process;

  -- Лёгкие проверки "до метастабильного момента"
  checks: process
  begin
    -- после SET (примерно к 220 ns) ожидаем Q=1/Qb=0 (с учётом задержек - чуть позже)
    wait for 230 ns;
    assert (Q_bal = '1' and Qb_bal = '0')
      report "WARN/FAIL: balanced latch did not settle to SET as expected"
      severity warning;

    -- после RESET (примерно к 420 ns)
    wait for 200 ns;
    assert (Q_bal = '0' and Qb_bal = '1')
      report "WARN/FAIL: balanced latch did not settle to RESET as expected"
      severity warning;

    -- после forbidden (примерно к 520 ns)
    wait for 120 ns;
    assert (Q_bal = '1' and Qb_bal = '1')
      report "WARN/FAIL: balanced latch did not show Q=Qb=1 in forbidden state"
      severity warning;

    -- после 750 ns: выведем статистику, а biased-версия должна выбрать устойчивое состояние
    wait for 260 ns;
    report "INFO: toggles of Q_bal in [600..750] ns = " & integer'image(toggles_q_bal) severity note;

    assert not (Q_bias = Qb_bias)
      report "FAIL: biased latch did not resolve (Q should differ from Qb after release)"
      severity error;

    report "TB FINISHED." severity note;
    wait;
  end process;

end TB;
