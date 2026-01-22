--------------------------------------------------------------------------------
-- Project 8: Hierarchical Design - Simple Communications System
-- Board   : Digilent Basys2
-- Language: VHDL
--
-- Идея:
--   (I0..I3) --MUX-->  sdata  --DeMUX--> (Y0..Y3)
--   Одинаковый выбор S(1:0) управляет и MUX, и DeMUX.
--
-- Входы (SW):
--   SW(3:0) = I0..I3 (данные)
--   SW(5:4) = S0..S1 (выбор)
--   SW(7:6) не используются (держать 0)
--
-- Выходы (LED):
--   LED(3:0) = Y0..Y3 (куда попали данные)
--   LED(4)   = sdata (сигнал в "общем канале")
--   LED(6:5) = S1:S0 (для контроля выбора)
--   LED(7)   = 0
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity P08_Hierarchical_Comms_System is
  port (
    SW  : in  std_logic_vector(7 downto 0);
    LED : out std_logic_vector(7 downto 0)
  );
end P08_Hierarchical_Comms_System;

architecture Structural of P08_Hierarchical_Comms_System is
  signal i     : std_logic_vector(3 downto 0);
  signal s     : std_logic_vector(1 downto 0);
  signal sdata : std_logic;
  signal y     : std_logic_vector(3 downto 0);
begin
  i <= SW(3 downto 0);    -- I0..I3
  s <= SW(5 downto 4);    -- S0..S1 (вектор S(1 downto 0))

  U_MUX: entity work.mux_4to1
    port map (
      d => i,
      s => s,
      y => sdata
    );

  U_DEMUX: entity work.demux_1to4
    port map (
      din => sdata,
      s   => s,
      y   => y
    );

  -- LED packing:
  -- LED(3:0)=Y0..Y3, LED(4)=sdata, LED(5)=S0, LED(6)=S1, LED(7)=0
  LED <= '0' & s(1) & s(0) & sdata & y;

end Structural;
