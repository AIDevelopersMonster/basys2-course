library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Comparator bit-slice:
-- inputs:  A, B, and incoming flags from less significant bits: GTI, LTI, EQI
-- outputs: updated flags to more significant bits: GTO, LTO, EQO
entity cmp_slice is
  port (
    A   : in  std_logic;
    B   : in  std_logic;
    GTI : in  std_logic;
    LTI : in  std_logic;
    EQI : in  std_logic;

    GTO : out std_logic;
    LTO : out std_logic;
    EQO : out std_logic
  );
end cmp_slice;

architecture RTL of cmp_slice is
  signal eq_ab : std_logic;
begin
  -- eq_ab = (A XNOR B)
  eq_ab <= not (A xor B);

  -- If already decided (GTI=1 or LTI=1), keep it.
  -- Otherwise (EQI=1), decide using this bit.
  GTO <= GTI or (EQI and (A and (not B)));
  LTO <= LTI or (EQI and ((not A) and B));
  EQO <= EQI and eq_ab;
end RTL;
