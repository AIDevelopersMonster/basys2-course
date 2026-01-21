--------------------------------------------------------------------------------
-- Testbench for Project 7: Barrel Shifter (4-bit)
-- Проверка:
--   Перебор всех комбинаций A, SH, DIR, FILL (256 векторов)
--   Контроль:
--     LED(3:0) == ожидаемому Y
--     LED(7:4) == A (как задумано для наглядности)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_P07_Shifter is
end tb_P07_Shifter;

architecture TB of tb_P07_Shifter is
  signal SW  : std_logic_vector(7 downto 0) := (others => '0');
  signal LED : std_logic_vector(7 downto 0);

  function shift4(
    a    : std_logic_vector(3 downto 0);
    sh   : std_logic_vector(1 downto 0);
    dir  : std_logic;
    fill : std_logic
  ) return std_logic_vector is
    variable y : std_logic_vector(3 downto 0);
  begin
    y := a;

    if dir = '0' then
      -- LEFT
      case sh is
        when "00" => y := a;
        when "01" => y := a(2 downto 0) & fill;
        when "10" => y := a(1 downto 0) & fill & fill;
        when "11" => y := a(0) & fill & fill & fill;
        when others => y := a;
      end case;
    else
      -- RIGHT
      case sh is
        when "00" => y := a;
        when "01" => y := fill & a(3 downto 1);
        when "10" => y := fill & fill & a(3 downto 2);
        when "11" => y := fill & fill & fill & a(3);
        when others => y := a;
      end case;
    end if;

    return y;
  end function;

begin
  DUT: entity work.P07_Shifter
    port map (
      SW  => SW,
      LED => LED
    );

  stim: process
    variable a_v    : std_logic_vector(3 downto 0);
    variable sh_v   : std_logic_vector(1 downto 0);
    variable dir_v  : std_logic;
    variable fill_v : std_logic;
    variable exp_y  : std_logic_vector(3 downto 0);
  begin
    -- Инициализация
    SW <= (others => '0');
    wait for 20 ns;

    for a_i in 0 to 15 loop
      a_v := std_logic_vector(to_unsigned(a_i, 4));

      for sh_i in 0 to 3 loop
        sh_v := std_logic_vector(to_unsigned(sh_i, 2));

        for dir_i in 0 to 1 loop
          if dir_i = 0 then dir_v := '0'; else dir_v := '1'; end if;

          for fill_i in 0 to 1 loop
            if fill_i = 0 then fill_v := '0'; else fill_v := '1'; end if;

            -- раскладка SW
            SW(3 downto 0) <= a_v;
            SW(5 downto 4) <= sh_v;
            SW(6)          <= dir_v;
            SW(7)          <= fill_v;

            wait for 10 ns;

            exp_y := shift4(a_v, sh_v, dir_v, fill_v);

            assert LED(7 downto 4) = a_v
              report "FAIL: LED(7..4) != A"
              severity error;

            assert LED(3 downto 0) = exp_y
              report "FAIL: Y mismatch at A=" & integer'image(a_i) &
                     " SH=" & integer'image(sh_i)
              severity error;
          end loop;
        end loop;
      end loop;
    end loop;

    report "TB PASSED: all 256 vectors OK." severity note;
    wait;
  end process;

end TB;
