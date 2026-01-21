# Basys2Project

Минимальный шаблон проекта под **Digilent Basys 2 (Spartan-3E)** для **Xilinx ISE**.

## Состав проекта

- `Basys2Project.vhd` — верхний модуль (top-level entity)
- `Basys2Project_tb.vhd` — тестбенч для ISim (Behavioral)
- `Basys2_100_250General.ucf` — ограничения пинов Basys 2
- `Basys2Project.xise` — файл проекта Xilinx ISE

> При создании нового проекта генератор автоматически заменяет `Basys2Project` на имя проекта,
> поэтому в вашей папке вы увидите, например: `P03_Majority_of_Five.vhd`, `P03_Majority_of_Five_tb.vhd` и т.д.

## Быстрый старт (ISE)

1. Откройте файл `*.xise` в **Xilinx ISE Project Navigator**.
2. Для прошивки платы через **Adept/JTAG** проверьте настройку:
   `Generate Programming File → Process Properties → Startup Options → FPGA Start-Up Clock = JTAG Clock`.
3. Соберите проект: `Synthesize → Implement Design → Generate Programming File`.
4. Прошейте `.bit` через Digilent Adept.

## Симуляция (ISim)

Тестбенч лежит рядом с top-level модулем: `*_tb.vhd`.

В ISE:

1. Переключитесь в **Simulation View**.
2. Убедитесь, что тестбенч добавлен в проект и выбран как top для **Behavioral Simulation**.
3. Запустите `Simulate Behavioral Model`.

Подсказки:

- Время симуляции задаётся в свойствах проекта (по умолчанию часто стоит 1000 ns).
- Значения `U`, `X` в волновом окне обычно возникают из-за неинициализированных сигналов в тестбенче.

## Договорённости по стилю VHDL

- Для комбинационной логики — `process(all)` или конкурентные присваивания.
- Для последовательной логики — один процесс с `rising_edge(...)` и явной инициализацией регистров.
- При необходимости используйте **синхронный сброс** (reset) как внутренний сигнал (на Basys 2 нет отдельной аппаратной линии reset «для вашей логики» — её задаёте вы сами через кнопку/переключатель).

## Задание / цель проекта

Опишите, что делает ваша схема, какие входы используются (SW/BTN/CLK), что выводится (LED/7SEG/VGA и т.д.),
и как повторить эксперимент.

---

Автор: _ваше имя_  
Плата: **Basys 2**, FPGA: **XC3S100E-CP132**
