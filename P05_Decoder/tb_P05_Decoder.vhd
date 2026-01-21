--------------------------------------------------------------------------------
-- Testbench for Project 5: Decoder (3-to-8) with Enable
-- Проверка:
--   Перебор EN ∈ {0,1} и A ∈ {0..7}
--   Контроль:
--     LED == ожидаемому one-hot (или нулям при EN=0)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_P05_Decoder is
end tb_P05_Decoder;

architecture TB of tb_P05_Decoder is
  signal SW  : std_logic_vector(7 downto 0) := (others => '0');
  signal LED : std_logic_vector(7 downto 0);

  -- ожидаемый one-hot результат
  function dec3to8(
    a  : std_logic_vector(2 downto 0);
    en : std_logic
  ) return std_logic_vector is
    variable y : std_logic_vector(7 downto 0) := (others => '0');
    variable i : integer;
  begin
    if en = '1' then
      i := to_integer(unsigned(a)); -- 0..7
      y(i) := '1';
    end if;
    return y;
  end function;

begin
  DUT: entity work.P05_Decoder
    port map (
      SW  => SW,
      LED => LED
    );

  stim: process
    variable a      : std_logic_vector(2 downto 0);
    variable en     : std_logic;
    variable exp_y  : std_logic_vector(7 downto 0);
  begin
    -- Инициализация, чтобы не было U/X
    SW <= (others => '0');
    wait for 20 ns;

    for en_i in 0 to 1 loop
      if en_i = 0 then en := '0'; else en := '1'; end if;

      for ai in 0 to 7 loop
        a := std_logic_vector(to_unsigned(ai, 3));

        SW(2 downto 0) <= a;
        SW(3)          <= en;
        SW(7 downto 4) <= (others => '0');
        wait for 10 ns;

        exp_y := dec3to8(a, en);

        assert LED = exp_y
          report "FAIL: LED != expected at EN=" & std_logic'image(en) &
                 " A=" & integer'image(ai)
          severity error;
      end loop;
    end loop;

    report "TB PASSED: all vectors OK." severity note;
    wait;
  end process;

end TB;
