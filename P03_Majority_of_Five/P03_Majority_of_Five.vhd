--=============================================================================
-- Project      : Basys2 Course - Project 3 (P03)
-- Module       : P03_Majority_of_Five
-- Description  : Комбинационная схема "Majority of Five".
--                Выход Y=1, если среди пяти входов A..E установлено
--                три или более единиц (sum >= 3).
--
-- Target board : Digilent Basys2 (Spartan-3E)
-- Inputs       : SW(4 downto 0)  -> A=SW0, B=SW1, C=SW2, D=SW3, E=SW4
-- Outputs      : LED(0)          -> Y (majority result)
--                LED(7 downto 1) -> 0
--
-- Notes        :
--  - Модуль не использует тактирование и reset (чистая комбинационная логика).
--  - Для корректной симуляции/синтеза избегайте множественных драйверов
--    одного и того же сигнала (LED задавайте одним присваиванием).
--
-- Author       : Alex Malachevsky
-- Repository   : https://github.com/AIDevelopersMonster/basys2-course
-- Date         : 2026-01-20
--=============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity P03_Majority_of_Five is
  port (
    SW  : in  std_logic_vector(7 downto 0);
    LED : out std_logic_vector(7 downto 0)
  );
end P03_Majority_of_Five;

architecture Behavioral of P03_Majority_of_Five is
  signal A, B, C, D, E : std_logic;
  signal Y             : std_logic;
begin
  -- Берём 5 переключателей: SW0..SW4
  A <= SW(0);
  B <= SW(1);
  C <= SW(2);
  D <= SW(3);
  E <= SW(4);

  -- Majority of 5: 1 если есть любые 3 единицы из 5
  Y <= (A and B and C) or  -- ABC
       (A and B and D) or  -- ABD
       (A and C and D) or  -- ACD
       (B and C and D) or  -- BCD
       (A and B and E) or  -- ABE
       (A and C and E) or  -- ACE
       (A and D and E) or  -- ADE
       (B and C and E) or  -- BCE
       (B and D and E) or  -- BDE
       (C and D and E);    -- CDE

  -- Вывод: LED0 = Y, остальные погасить
 LED <= (7 downto 1 => '0') & Y;
end Behavioral;
