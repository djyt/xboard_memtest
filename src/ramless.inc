/* Fake call/return helpers from the bootloader. Use A6 as return address (previously A7, but that makes mixing with regular C impossible). */

/* Call() macro, used to emulate call like behaviour without stack. Returns to the address in %A6. */
.macro CALL function
  movea.l #1f, %A6
  jmp \function
1: /* Return address */
.endm

.macro CALL_A5 function
  movea.l #1f, %A5
  jmp \function
1: /* Return address */
.endm

.macro CALL_RETURN function returnaddr
  movea.l #\returnaddr, %A6
  jmp \function
.endm

/* Return macro; jumps back to the address stored in %A6 */
.macro RETURN
  jmp (%A6)
.endm

.macro RETURN_A5
  jmp (%A5)
.endm
