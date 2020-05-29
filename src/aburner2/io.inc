/* Clear Watchdog (Also Enables Screen!) */
.macro WATCHDOG_CLEAR
  /*move.b #0xE3, IO1_PORTC*/
.endm

/* Disable Screen */
.macro DISABLE_SCREEN
  move.b #0xC3, IO1_PORTC
.endm

/* Enable Screen */
.macro ENABLE_SCREEN
  move.b #0xE3, IO1_PORTC
.endm

/* Flip halves of sprite RAM */
.macro FLIP_SPRITES
  move.w #0xFFFF, RENDER_TRIGGER
.endm

/* Super Hang On has no brake output afaik, so this probably isn't as useful */
.macro DIGITAL_RESET
.endm

.macro DIGITAL_OK
.endm

.macro DIGITAL_FAIL
.endm
