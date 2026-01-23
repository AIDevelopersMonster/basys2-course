# P12 - Magnitude Comparator (bit-slice), Basys2 (VHDL)

## Теория (по Digilent)
Magnitude comparator сравнивает два N-битных числа и формирует три выхода:
GT (A>B), LT (A<B), EQ (A=B). Digilent отмечает, что компараторы легко описать поведенчески,
но структурное проектирование удобно делать через bit-slice подход. :contentReference[oaicite:4]{index=4}

В bit-slice варианте каждый разряд получает не только A(n),B(n), но и "состояние сравнения"
от младших разрядов (GTI/LTI/EQI) и передаёт обновлённые флаги дальше (GTO/LTO/EQO). :contentReference[oaicite:5]{index=5}

## Назначение выводов (Basys2)
- SW(3:0)  = A[3:0]
- SW(7:4)  = B[3:0]
- LED(2)   = GT (A>B)
- LED(1)   = EQ (A=B)
- LED(0)   = LT (A<B)

## Примеры проверки на плате (обязательные)
1) A=9 (1001), B=6 (0110)
   SW = BAAAA = 0110_1001
   Ожидаем: GT=1, EQ=0, LT=0  → LED(2)=1

2) A=5 (0101), B=5 (0101)
   SW = 0101_0101
   Ожидаем: EQ=1 → LED(1)=1

3) A=3 (0011), B=12 (1100)
   SW = 1100_0011
   Ожидаем: LT=1 → LED(0)=1

## Симуляция
Simulation Sources → tb_P12_Comparator → Simulate Behavioral Model.
Тестбенч перебирает все 256 комбинаций и делает assert-проверки.
