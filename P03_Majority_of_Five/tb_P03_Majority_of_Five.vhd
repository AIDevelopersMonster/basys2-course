--=============================================================================
-- Project      : Basys2 Course — Project 3 (P03)
-- Testbench    : tb_P03_Majority_of_Five
-- DUT          : P03_Majority_of_Five
-- Description  :
--  Тестбенч для проверки схемы "Majority of Five".
--  Выполняет полный перебор 32 комбинаций входов SW(4 downto 0) и проверяет:
--    LED(0) = '1'  <=>  количество единиц на SW(4..0) >= 3.
--  Линии SW(7 downto 5) фиксируются в '0'.
--
-- Expected     :
--  - При несоответствии возникает assert severity error.
--  - При успешном прохождении всех тестов выводится сообщение "OK ..."
--
-- Simulation   : ISim / Behavioral Simulation (ISE 14.7)
--
-- Author       : Alex Malachevsky
-- Repository   : https://github.com/AIDevelopersMonster/basys2-course
-- Date         : 2026-01-20
--=============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_P03_Majority_of_Five is
end tb_P03_Majority_of_Five;

architecture sim of tb_P03_Majority_of_Five is
  signal SW  : std_logic_vector(7 downto 0) := (others => '0');
  signal LED : std_logic_vector(7 downto 0);

  -- Подсчёт количества '1' в SW(4 downto 0)
  function count_ones_5(v : std_logic_vector(4 downto 0)) return integer is
    variable c : integer := 0;
  begin
    for i in v'range loop
      if v(i) = '1' then
        c := c + 1;
      end if;
    end loop;
    return c;
  end function;
begin
  -- DUT (Device Under Test)
  uut: entity work.P03_Majority_of_Five
    port map (
      SW  => SW,
      LED => LED
    );

  stim: process
    variable v5      : std_logic_vector(4 downto 0);
    variable ones    : integer;
    variable expectY : std_logic;
  begin
    -- Небольшая пауза на старт симуляции
    wait for 10 ns;

    -- Полный перебор 0..31 для SW(4..0)
    for k in 0 to 31 loop
      v5 := std_logic_vector(to_unsigned(k, 5));

      -- Подать входы
      SW(4 downto 0) <= v5;
      SW(7 downto 5) <= (others => '0');

      wait for 10 ns; -- время на распространение в комбинационной логике

      -- Ожидаемое значение majority-of-5
      ones := count_ones_5(v5);
      if ones >= 3 then
        expectY := '1';
      else
        expectY := '0';
      end if;

      -- Проверка LED0
      assert LED(0) = expectY
        report "FAIL: k=" & integer'image(k) &
               " SW(4..0)=" & std_logic'image(v5(4)) & std_logic'image(v5(3)) &
                              std_logic'image(v5(2)) & std_logic'image(v5(1)) &
                              std_logic'image(v5(0)) &
               " ones=" & integer'image(ones) &
               " expected LED0=" & std_logic'image(expectY) &
               " got LED0=" & std_logic'image(LED(0))
        severity error;
    end loop;

    -- Если дошли сюда - всё ок
    assert false
      report "OK: All 32 combinations passed."
      severity note;

    wait; -- стоп
  end process;
end sim;
