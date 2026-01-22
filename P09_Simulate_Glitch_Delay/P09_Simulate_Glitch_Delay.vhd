--------------------------------------------------------------------------------
-- Project 9: Simulate Glitch and Delay in Combinational Circuits (VHDL/ISim)
--
-- Реализуем схему:
--   N1 = A & B
--   N2 = ~B
--   N3 = N2 & C
--   X  = N1 | N3
-- с задержками на каждом "элементе", чтобы увидеть glitch (hazard).
--
-- Дополнительно: опционально добавляем редундантный терм N4 = A & C
-- (консенсус) для устранения static-1 hazard:
--   X = (A&B) | (~B&C) | (A&C)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity P09_Simulate_Glitch_Delay is
  generic (
    T_AND1 : time := 1 ns;
    T_NOT  : time := 1 ns;
    T_AND2 : time := 1 ns;
    T_AND3 : time := 1 ns;  -- для A&C (если включим)
    T_OR   : time := 1 ns;
    FIX_STATIC_HAZARD : boolean := false
  );
  port (
    A : in  std_logic;
    B : in  std_logic;
    C : in  std_logic;
    X : out std_logic
  );
end P09_Simulate_Glitch_Delay;

architecture DelayModel of P09_Simulate_Glitch_Delay is
  signal N1, N2, N3, N4 : std_logic := '0';
begin
  -- transport: не "съедает" короткие импульсы, удобно для демонстрации глитча
  N1 <= transport (A and B)   after T_AND1;
  N2 <= transport (not B)     after T_NOT;
  N3 <= transport (N2 and C)  after T_AND2;
  N4 <= transport (A and C)   after T_AND3;

  GEN_NOFIX : if not FIX_STATIC_HAZARD generate
    X <= transport (N1 or N3) after T_OR;
  end generate;

  GEN_FIX : if FIX_STATIC_HAZARD generate
    X <= transport (N1 or N3 or N4) after T_OR;
  end generate;

end DelayModel;
