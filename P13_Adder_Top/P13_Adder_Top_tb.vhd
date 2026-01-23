library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_P13_Adder is
end;

architecture TB of tb_P13_Adder is
  signal A, B : std_logic_vector(3 downto 0) := (others => '0');
  signal CIN  : std_logic := '0';
  signal SUM  : std_logic_vector(3 downto 0);
  signal COUT : std_logic;
begin
  DUT: entity work.adder_4bit
    port map (
      A    => A,
      B    => B,
      CIN  => CIN,
      SUM  => SUM,
      COUT => COUT
    );

  process
    variable ai, bi : integer;
    variable ci     : integer;
    variable ref    : unsigned(4 downto 0); -- 5 бит: [4]=COUT, [3:0]=SUM
  begin
    --------------------------------------------------------------------------
    -- Инициализация (чтобы в waveform не было U)
    --------------------------------------------------------------------------
    A   <= (others => '0');
    B   <= (others => '0');
    CIN <= '0';
    wait for 10 ns;  -- важно: дать времени стабилизироваться

    -- Дополнительно "потрогаем" крайние случаи переноса
    A <= "1111"; B <= "0000"; CIN <= '0'; wait for 2 ns; -- 15 + 0 + 0
    A <= "1111"; B <= "0000"; CIN <= '1'; wait for 2 ns; -- 15 + 0 + 1
    A <= "1111"; B <= "1111"; CIN <= '0'; wait for 2 ns; -- 15 + 15 + 0 => COUT=1
    A <= "1111"; B <= "1111"; CIN <= '1'; wait for 2 ns; -- 15 + 15 + 1 => COUT=1

    --------------------------------------------------------------------------
    -- Полный перебор: A=0..15, B=0..15, CIN=0/1
    --------------------------------------------------------------------------
    for ai in 0 to 15 loop
      for bi in 0 to 15 loop
        for ci in 0 to 1 loop
          A   <= std_logic_vector(to_unsigned(ai, 4));
          B   <= std_logic_vector(to_unsigned(bi, 4));
          if ci = 0 then
            CIN <= '0';
          else
            CIN <= '1';
          end if;

          wait for 1 ns; -- время на распространение по комб.логике

          -- эталон: 5-битный результат
          ref := to_unsigned(ai, 5) + to_unsigned(bi, 5) + to_unsigned(ci, 5);

          -- проверка суммы
          assert SUM = std_logic_vector(ref(3 downto 0))
            report "SUM mismatch: A=" & integer'image(ai) &
                   " B=" & integer'image(bi) &
                   " CIN=" & integer'image(ci) &
                   " SUM=" & integer'image(to_integer(unsigned(SUM))) &
                   " REF_SUM=" & integer'image(to_integer(ref(3 downto 0)))
            severity error;

          -- проверка переноса
          assert COUT = std_logic(ref(4))
  report "COUT mismatch: A=" & integer'image(ai) &
         " B=" & integer'image(bi) &
         " CIN=" & integer'image(ci) &
         " COUT=" & std_logic'image(COUT) &
         " REF_COUT=" & std_logic'image(std_logic(ref(4)))
  severity error;


        end loop;
      end loop;
    end loop;

    report "TB PASSED: all cases OK (including carry chains)." severity note;
    wait;
  end process;

end TB;
