/* Used memory addresses. These are also used to initialize the memory mapper (not the sizes!), not for testing, so this should match the list in memregions.c */

.set HAVE_SUBCPU, 1

.set MAINCPU_HZ, 12000000
.set SUBCPU_HZ, 12000000
.set VIDEO_FPS, 60
.set VIDEO_SCANLINES, 262

.ifdef CPU0

.set CYCLES_PER_SCANLINE, (MAINCPU_HZ/(VIDEO_FPS*VIDEO_SCANLINES))

.equ MAINROM_BASE,    0x000000
.equ TILERAM_BASE,    0x0C0000
.equ TEXTRAM_BASE,    0x0D0000
.equ TILE_REGISTERS,  (TEXTRAM_BASE+0xe80)
.equ HW_MULTIPLY1,    0x0E0000                          /* Hardware multiplier (315-5248, IC107) */
.equ HW_DIVIDE1,      0x0E4000                          /* Hardware divider    (315-5249, IC108) */                          
.equ SPRITE_BASE,     0x100000
.equ RENDER_TRIGGER,  0x110000                          /* 315-5211A render trigger (w/o, lockup on read) */
.equ PALETTE_BASE,    0x120000
.equ IO1_BASE,        0x140000                          /* I/O chip #1 (IC160) */
.equ IO2_BASE,        0x150000                          /* I/O chip #2 (IC159) */
.equ IO_CTRL,         0x160000                          /* I/O control (w/o) (w/o, lockup on read) */
.equ SUBROM_BASE,     0x200000
.equ HW_MULTIPLY2,    0x2E0000                          /* Hardware multiplier (315-5248, IC30) */
.equ HW_DIVIDE2,      0x2E4000                          /* Hardware divider    (315-5249, IC37) */
.equ HW_COMPARE,      0x2E8000                          /* Hardware comparator (315-5250, IC53) */
.equ ROADRAM_BASE,    (SUBROM_BASE+0xEC000)
.equ ROADCTRL_BASE,   (SUBROM_BASE+0xEE000)

/* I/O registers */
.equ IO1_PORTA,       (IO1_BASE)+0x1
.equ IO1_PORTB,       (IO1_BASE)+0x3
.equ IO1_PORTC,       (IO1_BASE)+0x5                   /* D7: (Not connected)
                                                          D6: (/WDC) - watchdog reset
                                                          D5: Screen display (1= blanked, 0= displayed)
                                                          D4: (ADC2)
                                                          D3: (ADC1)
                                                          D2: (ADC0)
                                                          D1: (CONT) - affects sprite hardware
                                                          D0: Sound section reset (1= normal operation, 0= reset) */
.equ IO1_PORTD,       (IO1_BASE)+0x7
.equ IO1_REG1,        (IO1_BASE)+0xC

.endif

.ifdef CPU1

.set CYCLES_PER_SCANLINE, (SUBCPU_HZ/(VIDEO_FPS*VIDEO_SCANLINES))

.equ SUBROM_BASE,     0x000000

.endif /* CPU1 */

.ifdef HAVE_SUBCPU

.equ SUBRAM_BASE2,     (SUBROM_BASE+0x80000)
.equ ROADRAM_BASE2,    (SUBROM_BASE+0xEC000)
.equ ROADCTRL_BASE2,   (SUBROM_BASE+0xEE000)

.endif /* HAVE_SUBCPU */
