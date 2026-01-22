--------------------------------------------------------------------------------
-- SR-Latch (NAND cell), S_n and R_n are ACTIVE-LOW
--
-- Truth table (NAND latch):
--   S_n R_n | Q  Qb | Meaning
--    1   1  | hold  | store previous state
--    0   1  | 1  0  | SET
--    1   0  | 0  1  | RESET
--    0   0  | 1  1  | forbidden / confounded outputs
--
-- NOTE: This is a combinational loop (feedback). For FPGA design it's generally
-- considered bad practice unless you really know what you're doing. :contentReference[oaicite:1]{index=1}
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sr_latch_nand is
  generic (
    SIM        : boolean := true;      -- true: use transport delays (simulation)
    T_Q        : time    := 1 ns;       -- delay on Q path
    T_QB       : time    := 1 ns        -- delay on Qb path
  );
  port (
    S_n : in  std_logic;               -- active-low SET
    R_n : in  std_logic;               -- active-low RESET
    Q   : out std_logic;
    Qb  : out std_logic
  );
end sr_latch_nand;

architecture RTL of sr_latch_nand is
  signal q_i  : std_logic := '0';
  signal qb_i : std_logic := '1';
begin

  GEN_SIM : if SIM generate
    -- transport keeps short pulses -> easier to see unstable behavior
    q_i  <= transport not (S_n and qb_i) after T_Q;
    qb_i <= transport not (R_n and q_i ) after T_QB;
  end generate;

  GEN_HW : if not SIM generate
    -- no explicit delays (for synthesis / simple functional sim)
    q_i  <= not (S_n and qb_i);
    qb_i <= not (R_n and q_i );
  end generate;

  Q  <= q_i;
  Qb <= qb_i;

end RTL;
