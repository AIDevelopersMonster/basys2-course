# P01_Sw2Led_Passthrough — Switch-controlled LEDs (Basys2/ISE)

## Цель
Научиться:
- понимать роль top-level entity (граница цифровой системы)
- делать простые комбин. связи в HDL
- связывать логические порты с физическими выводами через UCF

## Аппаратные ресурсы
- Basys2: SW[7:0], LED[7:0]

## Реализация
Комбинаторное отображение:
LED <= SW

## Проверка
1) Собрать проект в ISE
2) Generate Programming File → Startup Options → FPGA Start-Up Clock = JTAG Clock
3) Прошить через Adept
4) Щёлкать SW и наблюдать LED

## Задания на модификацию
- Переставить соответствие: SW0 -> LED6, SW1 -> LED0 и т.д.
- Сделать инверсию: LED <= not SW

[![Видео #9](https://img.youtube.com/vi/SnHonhdoE6I/maxresdefault.jpg)](https://youtu.be/SnHonhdoE6I)

