library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cmp_nbit is
  generic (
    N : positive := 4
  );
  port (
    A  : in  std_logic_vector(N-1 downto 0);
    B  : in  std_logic_vector(N-1 downto 0);
    GT : out std_logic;
    LT : out std_logic;
    EQ : out std_logic
  );
end cmp_nbit;

architecture Structural of cmp_nbit is
  signal gt_chain : std_logic_vector(N downto 0);
  signal lt_chain : std_logic_vector(N downto 0);
  signal eq_chain : std_logic_vector(N downto 0);
begin
  -- Initial condition for LSB stage: "equal so far"
  gt_chain(0) <= '0';
  lt_chain(0) <= '0';
  eq_chain(0) <= '1';

  -- LSB -> MSB chain
  gen: for i in 0 to N-1 generate
    U: entity work.cmp_slice
      port map (
        A   => A(i),
        B   => B(i),
        GTI => gt_chain(i),
        LTI => lt_chain(i),
        EQI => eq_chain(i),
        GTO => gt_chain(i+1),
        LTO => lt_chain(i+1),
        EQO => eq_chain(i+1)
      );
  end generate;

  -- Final outputs from MSB stage
  GT <= gt_chain(N);
  LT <= lt_chain(N);
  EQ <= eq_chain(N);
end Structural;
