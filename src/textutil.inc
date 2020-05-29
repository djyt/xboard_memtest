.macro PRINT string color
  move.w #\color, %D0
  move #\string, %A0
  CALL(_print)
.endm
 
.macro NEWLINE
  move.l %A4, %D0
  add.l #((TEXT_WIDTH*2)-1), %D0
  and.l #~((TEXT_WIDTH*2)-1), %D0
  add.l #(TEXT_INDENT*2), %D0
  move.l %D0, %A4
.endm

.global COLOR_WHITE
.global COLOR_RED
.global COLOR_YELLOW
.global COLOR_GREEN
.global COLOR_CYAN

.equ TEXT_INDENT,  26
.equ TEXT_WIDTH,   64
.equ TEXT_HEIGHT,  32
