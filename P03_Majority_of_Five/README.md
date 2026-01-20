# Project 3 — Majority of Five (Basys2, VHDL)

**Задача:** реализовать комбинационную схему *majority-of-5*: выход равен `1`, если среди пяти входов установлено **три или больше единиц**.

Проект рассчитан на плату **Digilent Basys2 (Spartan-3E)** и **Xilinx ISE 14.7** (в т.ч. официальную VM для Windows 10/11).

---

## Соответствие сигналов плате

В этом проекте используется простое и наглядное подключение:

- `SW0..SW4` → пять входов `A..E`
- `LED0` → выход `Y` (результат функции большинства)

Остальные светодиоды (`LED7..LED1`) гасим.

---

## Теория

### 1) Определение функции большинства

Пусть есть пять бинарных входов:

- `A, B, C, D, E ∈ {0,1}`

Функция *majority-of-5* определяется так:

- `Y = 1`, если `A + B + C + D + E ≥ 3`
- иначе `Y = 0`

Интуитивно: «LED загорается, если *за* проголосовали минимум трое из пяти».

### 2) Сколько наборов входов дают единицу

Всего наборов: `2^5 = 32`.

Единицу дают наборы с числом единиц `k = 3,4,5`. Их количество:

- `C(5,3) + C(5,4) + C(5,5) = 10 + 5 + 1 = 16`

То есть ровно **половина** всех комбинаций (16 из 32) должна зажигать `LED0`.

### 3) Булева форма (SOP / «сумма произведений»)

Условие «минимум 3 единицы» можно записать через дизъюнкцию всех сочетаний по 3 входа:

```
Y = ABC + ABD + ACD + BCD +
    ABE + ACE + ADE + BCE + BDE + CDE
```

Здесь `+` — логическое ИЛИ, а конкатенация `ABC` — логическое И.

Почему достаточно только троек?
- Если на входах уже **4** или **5** единиц, то **какая-то тройка** среди них тоже единичная, значит выражение всё равно станет `1`.

На практике для FPGA можно реализовать это выражение напрямую, либо через «арифметический» подход (подсчитать число единиц и сравнить с 3). Синтезатор ISE в любом случае выполнит оптимизацию на уровне логических элементов.

---

## Практическая реализация на VHDL

### Важный нюанс про `LED` и значения `X` в симуляции

В VHDL **нельзя** без необходимости задавать один и тот же сигнал (например, `LED`) **двумя параллельными присваиваниями**. Это создаёт *два драйвера* на одну линию и в симуляции часто приводит к `X` (конфликт 0 и 1).

Поэтому `LED` формируется **одним** присваиванием целого вектора.

### Исходник: `P03_Majority_of_Five.vhd`

```vhdl
--=============================================================================
-- Project      : Basys2 Course — Project 3 (P03)
-- Module       : P03_Majority_of_Five
-- Description  : Majority-of-5. LED0=1, если среди SW0..SW4 >=3 единиц.
-- Target board : Digilent Basys2 (Spartan-3E)
-- Inputs       : SW(4 downto 0)  -> A=SW0, B=SW1, C=SW2, D=SW3, E=SW4
-- Outputs      : LED(0)          -> Y
--                LED(7 downto 1) -> 0
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

  -- LED0 = Y, остальные = 0 (ОДНО присваивание всего вектора)
  LED <= (7 downto 1 => '0') & Y;
end Behavioral;
```

### Альтернативная идея реализации (через подсчёт единиц)

Иногда удобнее мыслить «как в математике»: посчитать число единиц и сравнить с 3. Для 5 входов это можно сделать и вручную, и синтезатор создаст ту же комбинационную структуру.

> Для учебного проекта достаточно SOP-реализации выше; этот блок — просто как вариант.

---

## Ограничения (UCF) — минимальный пример

Если вы используете общий UCF-шаблон, достаточно оставить только нужные линии (`SW0..SW4` и `LED0`).

Пример (имена должны совпадать с вашим top-модулем):

```ucf
NET "SW<0>"  LOC = "P11";
NET "SW<1>"  LOC = "L3";
NET "SW<2>"  LOC = "K3";
NET "SW<3>"  LOC = "B4";
NET "SW<4>"  LOC = "G3";

NET "LED<0>" LOC = "M5";
```

> Точные `LOC` берутся из Basys2 Reference Manual (разводка переключателей/светодиодов).

---

## Симуляция в Xilinx ISE (ISim)

### 1) Подготовка

В проект добавляются **два файла**:

- `P03_Majority_of_Five.vhd` — устройство (DUT)
- `tb_P03_Majority_of_Five.vhd` — testbench

### 2) Запуск Behavioral simulation

1. В левой панели ISE переключите радиокнопку **Simulation** (не Implementation).
2. Выберите режим **Behavioral Simulation**.
3. В дереве *Sources* выделите `tb_P03_Majority_of_Five` и назначьте **Top for Simulation**.
4. В *Processes* запустите **Simulate Behavioral Model**.

Если тесты проходят, в консоли ISim будет сообщение вида:

- `OK: All 32 combinations passed.`

---

## Testbench

### Зачем нужен testbench

Проверка «в железе» важна, но **симуляция быстрее и надёжнее**:

- вы тестируете логику без UCF и платы
- автоматически перебираете множество случаев
- сразу видите ошибки (через `assert`)

### Что делает этот testbench

- Полный перебор всех 32 комбинаций `SW(4..0)`
- Подсчёт количества единиц
- Сравнение эталона (>=3) с `LED(0)`
- При ошибке — `assert severity error`

### Исходник: `tb_P03_Majority_of_Five.vhd`

```vhdl
--=============================================================================
-- Project      : Basys2 Course — Project 3 (P03)
-- Testbench    : tb_P03_Majority_of_Five
-- DUT          : P03_Majority_of_Five
-- Description  : Перебор 32 комбинаций SW(4..0), проверка LED0.
-- Simulation   : ISim / Behavioral Simulation (ISE 14.7)
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
  -- DUT
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
    -- Пауза на старт
    wait for 10 ns;

    -- Полный перебор 0..31 для SW(4..0)
    for k in 0 to 31 loop
      v5 := std_logic_vector(to_unsigned(k, 5));

      -- Подать входы
      SW(4 downto 0) <= v5;
      SW(7 downto 5) <= (others => '0');

      wait for 10 ns; -- время на распространение комбинационной логики

      -- Эталон majority-of-5
      ones := count_ones_5(v5);
      if ones >= 3 then
        expectY := '1';
      else
        expectY := '0';
      end if;

      -- Проверка LED0
      assert LED(0) = expectY
        report "FAIL: k=" & integer'image(k) &
               " ones=" & integer'image(ones) &
               " expected LED0=" & std_logic'image(expectY) &
               " got LED0=" & std_logic'image(LED(0))
        severity error;
    end loop;

    -- Если дошли сюда — всё ок
    assert false report "OK: All 32 combinations passed." severity note;
    wait;
  end process;

end sim;
```

---

## Типичные проблемы и их причины

### В симуляции видны `U` и `X`

- `U` (Uninitialized) — сигнал ещё не получил значения.
- `X` (Unknown) — конфликт драйверов или распространение неопределённости.

Самая частая причина `X` в этом проекте — **два параллельных присваивания** одному и тому же `LED`.
Решение: формируйте `LED` **одним** присваиванием (как в коде выше).

### Симуляция «идёт 1 мкс»

Это просто выбранный интервал Run в ISim (например, 1000 ns = 1 µs). На корректность схемы это не влияет.

### Есть ли на плате reset «по умолчанию»?

Для **комбинационной** логики reset не нужен.

Для **последовательной** (счётчики, автоматы, регистры) reset обычно добавляют как отдельный вход и привязывают к кнопке `BTN*`.

---

## Проверка на плате

1. Соберите проект: **Synthesize → Implement Design → Generate Programming File**.
2. Для прошивки через JTAG/Adept в ISE обычно требуется настройка:
   **FPGA Start-Up Clock → JTAG Clock**
   (Generate Programming File → Process Properties → Startup Options).
3. Прошейте `.bit` на плату и проверьте:
   - включите любые **три** из `SW0..SW4` → `LED0` должен загореться.

