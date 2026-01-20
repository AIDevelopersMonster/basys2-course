--------------------------------------------------------------------------------
-- Testbench for Project 4: Multiplexer (4-to-1)
-- Проверка:
--   Перебор всех комбинаций SW(5 downto 0) = {S1,S0,D3,D2,D1,D0}
--   Контроль:
--     LED(0)     == ожидаемому Y
--     LED(4..1)  == ожидаемому one-hot выбора
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_P04_Multiplexer is
end tb_P04_Multiplexer;

architecture TB of tb_P04_Multiplexer is
  signal SW  : std_logic_vector(7 downto 0) := (others => '0');
  signal LED : std_logic_vector(7 downto 0);

  -- Ожидаемый выход мультиплексора
  function mux4(
    d : std_logic_vector(3 downto 0);
    s : std_logic_vector(1 downto 0)
  ) return std_logic is
  begin
    case s is
      when "00" => return d(0);
      when "01" => return d(1);
      when "10" => return d(2);
      when "11" => return d(3);
      when others => return '0';
    end case;
  end function;

  -- Ожидаемый one-hot код выбора
  function onehot4(
    s : std_logic_vector(1 downto 0)
  ) return std_logic_vector is
    variable r : std_logic_vector(3 downto 0);
  begin
    case s is
      when "00" => r := "0001";
      when "01" => r := "0010";
      when "10" => r := "0100";
      when "11" => r := "1000";
      when others => r := "0000";
    end case;
    return r;
  end function;

begin
  -- DUT
  DUT: entity work.P04_Multiplexer
    port map (
      SW  => SW,
      LED => LED
    );

  stim: process
    variable v6      : std_logic_vector(5 downto 0);
    variable d       : std_logic_vector(3 downto 0);
    variable s       : std_logic_vector(1 downto 0);
    variable exp_y   : std_logic;
    variable exp_sel : std_logic_vector(3 downto 0);
  begin
    -- Инициализация (чтобы не ловить U/X из-за неопределённых входов)
    SW <= (others => '0');
    wait for 20 ns;

    -- Полный перебор 6 бит: S(1..0) и D(3..0)
    for i in 0 to 63 loop
      v6 := std_logic_vector(to_unsigned(i, 6));

      -- v6(5..4)=S, v6(3..0)=D
      SW(5 downto 0) <= v6;
      SW(7 downto 6) <= "00";
      wait for 10 ns;

      d := SW(3 downto 0);
      s := SW(5 downto 4);

      exp_y   := mux4(d, s);
      exp_sel := onehot4(s);

      assert LED(0) = exp_y
        report "FAIL: LED(0) != Y at i=" & integer'image(i)
        severity error;

      assert LED(4 downto 1) = exp_sel
        report "FAIL: LED(4..1) != onehot(S) at i=" & integer'image(i)
        severity error;
    end loop;

    report "TB PASSED: all 64 vectors OK." severity note;
    wait;
  end process;

end TB;
