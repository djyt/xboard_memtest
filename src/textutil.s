.include "ramless.inc"
.include "textutil.inc"

.section .text

.global _print
.global _printhex6
.global _printhex2

# Basic printing helper.
# Read data from and modify A0; 
# D0. High byte of D0 = color.
_print:
  move.b (%A0)+, %D0 /* read character into low byte of D0 */
  beq _print_end
  move.w %D0, (%A4)+ /* A4 = destination cursor */
  bra _print  
_print_end:
  RETURN

# Print HEX address (in yellow).
# D2 = input; modify D1, D2, A0.
# destination = (A4)+
_printhex6:
  move.w #5, %D2
_printhex6_2: /* used for printhex2 */
  rol.l #8, %D0
  rol.l #4, %D0
  move #_hexlookup, %A0
_printhex_loop:
  move.l %D0, %D1
  and.l #0xf, %D1
  move.b (%D1, %A0), %D1
  or.w #COLOR_YELLOW, %D1
  move.w %D1, (%A4)+ /* A4 = destination cursor */
  
  rol.l #4, %D0  
  dbra %D2, _printhex_loop
  RETURN

_printhex2:
  move.w #1, %D2
  rol.l #8, %D0
  rol.l #8, %D0
  jmp _printhex6_2

.section .rodata

_hexlookup:
.ascii "0123456789ABCDEF"
