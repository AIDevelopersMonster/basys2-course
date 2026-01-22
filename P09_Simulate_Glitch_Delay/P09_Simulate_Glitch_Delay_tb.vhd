--------------------------------------------------------------------------------
-- Testbench:  glitch +  
--    Digilent: A,C , B . :contentReference[oaicite:4]{index=4}
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_P09_Simulate_Glitch_Delay is
end tb_P09_Simulate_Glitch_Delay;

architecture TB of tb_P09_Simulate_Glitch_Delay is
  signal A, B, C : std_logic := '0';
  signal X_haz   : std_logic;
  signal X_fix   : std_logic;

  constant T_AND1 : time := 5 ns;
  constant T_NOT  : time := 5 ns;
  constant T_AND2 : time := 5 ns;
  constant T_OR   : time := 5 ns;

  --     (  T_OR):
  -- (T_NOT + T_AND2) - T_AND1 = 1ns  (1,1,1)
  constant T_GLITCH_EXP : time := (T_NOT + T_AND2) - T_AND1;

begin
  -- DUT 1:  
  U_HAZ: entity work.P09_Simulate_Glitch_Delay
    generic map (
      T_AND1 => T_AND1,
      T_NOT  => T_NOT,
      T_AND2 => T_AND2,
      T_OR   => T_OR,
      FIX_STATIC_HAZARD => false
    )
    port map (
      A => A, B => B, C => C, X => X_haz
    );

  -- DUT 2:  (   A&C)
  U_FIX: entity work.P09_Simulate_Glitch_Delay
    generic map (
      T_AND1 => T_AND1,
      T_NOT  => T_NOT,
      T_AND2 => T_AND2,
      T_OR   => T_OR,
      FIX_STATIC_HAZARD => true
    )
    port map (
      A => A, B => B, C => C, X => X_fix
    );

  -- :   Digilent (  ,   VHDL) :contentReference[oaicite:5]{index=5}
  stim: process
    variable k  : integer;
    variable ac : unsigned(1 downto 0);
  begin
    A <= '0'; B <= '0'; C <= '0';
    wait for 20 ns;

    for k in 0 to 3 loop
      ac := to_unsigned(k, 2);
      -- {A,C} = k  (A =  , C = )
      A <= std_logic(ac(1));
      C <= std_logic(ac(0));

      wait for 1 ns;
      B <= '1';
      wait for 5 ns;
      B <= '0';
      wait for 5 ns;
      wait for 5 ns;
    end loop;

    report "TB DONE: stimulus finished." severity note;
    wait;
  end process;

  --  :   A=C=1   B:1->0
  measure: process
    variable t_fall, t_rise : time;
    variable width          : time;
  begin
    --   A=1, C=1  B=1
    wait until (A='1' and C='1' and B='1');
    --   B
    wait until (B='0');

    --      "0"
    wait until (X_haz = '0');
    t_fall := now;
    wait until (X_haz = '1');
    t_rise := now;

    width := t_rise - t_fall;
    report "Measured glitch width (hazard) = " & time'image(width) severity note;

    assert width = T_GLITCH_EXP
      report "FAIL: glitch width differs from expected " & time'image(T_GLITCH_EXP)
      severity error;

    --       X_fix   '1'
    assert X_fix = '1'
      report "FAIL: fixed circuit dropped low (should eliminate static glitch)"
      severity error;

    report "TB PASSED: glitch observed and fixed version stable." severity note;
    wait;
  end process;

end TB;
