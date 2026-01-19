-- ============================================================================
-- Project       : P01_Sw2Led_Passthrough
-- Board         : Digilent Basys 2 (Spartan-3E)
-- Toolchain     : Xilinx ISE WebPACK
-- Top entity    : P01_Sw2Led_Passthrough
-- Constraints   : Basys2_100_250General.ucf
--
-- Goal          : Отобразить состояние переключателей SW(7:0) на светодиоды LED(7:0).
-- Theory        : Комбин. "сквозное соединение" (concurrent assignment).
--
-- I/O mapping   : UCF использует имена портов SW<7:0> и LED<7:0>.
-- Expected      : SWi = '1'  ->  LEDi горит, SWi = '0' -> LEDi погашен.
--
-- Notes         : В ISE для JTAG/Adept: FPGA Start-Up Clock = JTAG Clock.
-- Author        : Alex Valachevsky
-- Date          : 2026-01-19
-- ============================================================================
library IEEE;
  use IEEE.STD_LOGIC_1164.ALL;
  use IEEE.STD_LOGIC_ARITH.ALL;
  use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity P01_Sw2Led_Passthrough is
  port (
    -- Clock inputs
    MCLK      : in    std_logic;
    UCLK      : in    std_logic;

    -- User physical inputs
    BTN       : in    std_logic_vector (3 downto 0);
    SW        : in    std_logic_vector (7 downto 0);

    -- User LED/Display outputs
    LED       : out   std_logic_vector (7 downto 0);
    SEG       : out   std_logic_vector (6 downto 0);
    AN        : out   std_logic_vector (3 downto 0);
    DP        : out   std_logic;

    -- VGA Interface
    VGA_RED   : out   std_logic_vector (2 downto 0);
    VGA_GREEN : out   std_logic_vector (2 downto 0);
    VGA_BLUE  : out   std_logic_vector (2 downto 1);
    VGA_HS    : out   std_logic;
    VGA_VS    : out   std_logic;

    -- PS2
    PS2C      : inout std_logic;
    PS2D      : inout std_logic;

    -- Expansion headers (6-pin, 4 data connections each)
    PIO       : inout std_logic_vector (87 downto 72);

    -- Data interface to PC via USB
    EppAstb   : in    std_logic;
    EppDstb   : in    std_logic;
    EppWr     : in    std_logic;
    EppWait   : out   std_logic;
    EppDB     : inout std_logic_vector (7 downto 0)
  );
end P01_Sw2Led_Passthrough;

architecture Structural of P01_Sw2Led_Passthrough is
begin
  ---------------------------------------------------------------------------
  -- Project 1 logic: switches control LEDs (8 -> 8)
  ---------------------------------------------------------------------------
  LED <= SW;

  ---------------------------------------------------------------------------
  -- Safe defaults for the rest of the board I/O
  ---------------------------------------------------------------------------
  -- 7-seg on Basys2 is typically active-low, so '1' turns segments/anodes off
  SEG <= (others => '1');
  AN  <= (others => '1');
  DP  <= '1';

  -- VGA outputs low
  VGA_RED   <= (others => '0');
  VGA_GREEN <= (others => '0');
  VGA_BLUE  <= (others => '0');
  VGA_HS    <= '0';
  VGA_VS    <= '0';

  -- EPP: no-ack by default
  EppWait <= '0';

  -- Tristate all INOUTs
  PS2C <= 'Z';
  PS2D <= 'Z';
  PIO  <= (others => '0') when (false) else (others => 'Z');
  EppDB <= (others => '0') when (false) else (others => 'Z');
end Structural;