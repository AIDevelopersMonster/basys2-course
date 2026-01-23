# Project 11 - Blinking LEDs (Basys2, VHDL)

🎬 Видео (#19): https://youtu.be/ZMLO5E4rI3E

## 
    :     "",  
****,         1-8 .

##  ( )
   `MCLK` = 50 .     1  (/  0.5 ),
    :

`DIV = CLK_HZ / (2 * BLINK_HZ)` .

  `cnt`  0  `DIV-1`,   :
-  `cnt`
-   LED (  )

##   
- `BTN0` - reset ()
- `SW(1:0)` - :
  - `00` = 1 Hz
  - `01` = 2 Hz
  - `10` = 4 Hz
  - `11` = 8 Hz
- `SW(2)` - :
  - `0` -   LED ( 00 <-> FF)
  - `1` - " "   (ring)

##     ( )
1)  .bit,  `BTN0`:
   -   `SW2=0` LED   `00000000`,   .
2)  `SW(2)=0`, `SW(1:0)=00`:
   -  LED     .
3)  `SW(2)=1`:
   -     `00000001`   ""  .
4)  `SW(1:0)`  `11`:
   - /  .

##  (ISim)
  `CLK_HZ=64`,         `assert`.
: Simulation Sources -> tb_P11_Blinking_LEDs -> Simulate Behavioral Model.

## UCF / Bitstream
    `MCLK`  `LED`,  `BTN0`  `SW`.
   `Basys2_100_250General.ucf`     :
- `NET "MCLK" ...`
- `NET "LED<7:0>" ...`
- `NET "BTN<0>" ...`
- `NET "SW<2:0>" ...`
  /.


[![Видео #19](https://img.youtube.com/vi/ZMLO5E4rI3E/maxresdefault.jpg)](https://youtu.be/ZMLO5E4rI3E)
