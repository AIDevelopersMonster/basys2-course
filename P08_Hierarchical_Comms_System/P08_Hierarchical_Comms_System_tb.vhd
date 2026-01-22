--------------------------------------------------------------------------------
-- Testbench for Project 8: Hierarchical Comms System
-- Перебор:
--   I(3:0) = 0..15, S = 0..3  => 64 вектора
-- Проверка:
--   sdata = I(sel)
--   y(sel) = sdata, остальные y = 0
--   LED(6:5)=S, LED(4)=sdata, LED(3:0)=y
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_P08_Hierarchical_Comms_System is
end tb_P08_Hierarchical_Comms_System;

architecture TB of tb_P08_Hierarchical_Comms_System is
  signal SW  : std_logic_vector(7 downto 0) := (others => '0');
  signal LED : std_logic_vector(7 downto 0);

  function pick_bit(i : std_logic_vector(3 downto 0);
                    s : std_logic_vector(1 downto 0)) return std_logic is
  begin
    case s is
      when "00" => return i(0);
      when "01" => return i(1);
      when "10" => return i(2);
      when "11" => return i(3);
      when others => return '0';
    end case;
  end function;

  function demux4(din : std_logic;
                  s   : std_logic_vector(1 downto 0)) return std_logic_vector is
    variable y : std_logic_vector(3 downto 0) := (others => '0');
  begin
    if din = '1' then
      case s is
        when "00" => y(0) := '1';
        when "01" => y(1) := '1';
        when "10" => y(2) := '1';
        when "11" => y(3) := '1';
        when others => y := (others => '0');
      end case;
    end if;
    return y;
  end function;

begin
  DUT: entity work.P08_Hierarchical_Comms_System
    port map (
      SW  => SW,
      LED => LED
    );

  stim: process
    variable i_v     : std_logic_vector(3 downto 0);
    variable s_v     : std_logic_vector(1 downto 0);
    variable exp_sd  : std_logic;
    variable exp_y   : std_logic_vector(3 downto 0);
  begin
    SW <= (others => '0');
    wait for 20 ns;

    for i_i in 0 to 15 loop
      i_v := std_logic_vector(to_unsigned(i_i, 4));

      for s_i in 0 to 3 loop
        s_v := std_logic_vector(to_unsigned(s_i, 2));

        SW(3 downto 0) <= i_v;
        SW(5 downto 4) <= s_v;
        SW(7 downto 6) <= "00";
        wait for 10 ns;

        exp_sd := pick_bit(i_v, s_v);
        exp_y  := demux4(exp_sd, s_v);

        assert LED(6 downto 5) = s_v
          report "FAIL: LED(6..5) != S"
          severity error;

        assert LED(4) = exp_sd
          report "FAIL: sdata mismatch"
          severity error;

        assert LED(3 downto 0) = exp_y
          report "FAIL: Y mismatch at I=" & integer'image(i_i) &
                 " S=" & integer'image(s_i)
          severity error;
      end loop;
    end loop;

    report "TB PASSED: all 64 vectors OK." severity note;
    wait;
  end process;

end TB;
