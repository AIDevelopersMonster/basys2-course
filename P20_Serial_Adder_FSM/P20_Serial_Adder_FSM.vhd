library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =========================================================
-- P20: Serial Adder (4-bit) implemented as FSM + Datapath
-- BTN3 = LOAD/RESET (edge)
-- BTN0 = STEP       (edge) : advances exactly one bit of addition
-- =========================================================

entity P20_Serial_Adder_FSM is
  port (
    MCLK : in  std_logic;
    BTN  : in  std_logic_vector(3 downto 0); -- BTN0 STEP, BTN3 LOAD
    SW   : in  std_logic_vector(7 downto 0); -- SW0-3=A, SW4-7=B
    LED  : out std_logic_vector(7 downto 0)
  );
end P20_Serial_Adder_FSM;

architecture RTL of P20_Serial_Adder_FSM is
  constant N : integer := 4;

  type fsm_state_t is (
    ST_IDLE,
    ST_LOAD,
    ST_ADD,    -- wait for STEP; on STEP perform one-bit add
    ST_SHIFT,  -- shift A,B right
    ST_CHECK,  -- inc bit_idx and decide next
    ST_DONE
  );

  signal state, next_state : fsm_state_t := ST_IDLE;

  signal a_reg, b_reg : std_logic_vector(N-1 downto 0) := (others => '0');
  signal sum_reg      : std_logic_vector(N-1 downto 0) := (others => '0');
  signal carry        : std_logic := '0';
  signal bit_idx      : unsigned(2 downto 0) := (others => '0');

  -- edge detect (simple, for simulation; for board you may add debounce)
  signal btn0_d, btn3_d : std_logic := '0';
  signal step_pulse, load_pulse : std_logic := '0';

begin
  -- Button edge detect (rising edge pulses)
  process(MCLK)
  begin
    if rising_edge(MCLK) then
      step_pulse <= BTN(0) and not btn0_d;
      load_pulse <= BTN(3) and not btn3_d;
      btn0_d <= BTN(0);
      btn3_d <= BTN(3);
    end if;
  end process;

  -- State register
  process(MCLK)
  begin
    if rising_edge(MCLK) then
      state <= next_state;
    end if;
  end process;

  -- Next state logic
  process(state, load_pulse, step_pulse, bit_idx)
  begin
    next_state <= state;
    case state is
      when ST_IDLE =>
        if load_pulse = '1' then
          next_state <= ST_LOAD;
        end if;

      when ST_LOAD =>
        next_state <= ST_ADD;

      when ST_ADD =>
        if step_pulse = '1' then
          next_state <= ST_SHIFT;
        end if;

      when ST_SHIFT =>
        next_state <= ST_CHECK;

      when ST_CHECK =>
        if bit_idx = to_unsigned(N-1, bit_idx'length) then
          next_state <= ST_DONE;
        else
          next_state <= ST_ADD;
        end if;

      when ST_DONE =>
        if load_pulse = '1' then
          next_state <= ST_LOAD;
        end if;
    end case;
  end process;

  -- Datapath (IMPORTANT: do NOT update in ST_ADD unless STEP occurred)
  process(MCLK)
    variable s, c : std_logic;
  begin
    if rising_edge(MCLK) then
      case state is
        when ST_LOAD =>
          a_reg   <= SW(3 downto 0);
          b_reg   <= SW(7 downto 4);
          sum_reg <= (others => '0');
          carry   <= '0';
          bit_idx <= (others => '0');

        when ST_ADD =>
          if step_pulse = '1' then
            s := a_reg(0) xor b_reg(0) xor carry;
            c := (a_reg(0) and b_reg(0)) or
                 (a_reg(0) and carry) or
                 (b_reg(0) and carry);
            sum_reg(to_integer(bit_idx)) <= s;
            carry <= c;
          end if;

        when ST_SHIFT =>
          a_reg <= '0' & a_reg(N-1 downto 1);
          b_reg <= '0' & b_reg(N-1 downto 1);

        when ST_CHECK =>
          bit_idx <= bit_idx + 1;

        when others =>
          null;
      end case;
    end if;
  end process;

  -- LEDs
  LED(3 downto 0) <= sum_reg;
  LED(4)          <= carry when state = ST_DONE else '0';
  LED(7 downto 5) <= std_logic_vector(bit_idx);

end RTL; 