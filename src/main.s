/* 
   X-Board memory test. 
   Written in assembler in order to avoid stack usage during the memory test of the main RAMs.
   
   TODO: Figure out Watchdog usage (IO_PORTC, but never seems to be actively set?)
         Do we need to have interrupts enabled for the first road swap? 
*/   

.include "config.inc"
.include "io.inc"
.include "textutil.inc"
.include "ramless.inc"
.include "shared.inc"

.text 

.ifdef HAVE_SUBCPU

# Reset SUB cpu.
.global ResetSubCPU
ResetSubCPU:
  /* Reset second CPU, and zero out the initial program counter */
  reset
  nop
  nop
  clr.l SUBRAM_BASE2+4
  clr.l SUBRAM_BASE2
  nop
  nop
  reset
  RETURN
  
.endif /* HAVE_SUBCPU */

.macro WAIT_VBLANK
  move.b #1, _vblank_wait_flag
1:
  tst.b _vblank_wait_flag
  bne 1b
.endm

.global WaitVBlank
WaitVBlank:
  move.b #1, _vblank_wait_flag
1:
  tst.b _vblank_wait_flag
  bne 1b
RETURN

# Assumes IRQ4 is enabled.  
.global SwapRoad
SwapRoad:
  move.l #ROADRAM_BASE, %A0
  move.l #0x08000800, %D0 /* Set Road to Solid Colour */
  move.w #0x7F, %D1
_roadclear_loop:

  move.l %D0, (%A0)+
  dbra   %D1, _roadclear_loop

  WAIT_VBLANK
  move.b #4, ROADCTRL_BASE+1
  tst.b ROADCTRL_BASE+1
  WAIT_VBLANK  
  RETURN
  
# Initialize/restore palette.
.global InitPalette
InitPalette:
  /* Clear Road Palette */
  move.l #(PALETTE_BASE+(0x2F00)), %A0
  clr.w %D0
  move.w #0xf, %D1
_roadpalette_loop:
  move.w %D0, (%A0)+ /* 128 entries */
  move.w %D0, (%A0)+
  move.w %D0, (%A0)+
  move.w %D0, (%A0)+
  move.w %D0, (%A0)+
  move.w %D0, (%A0)+
  move.w %D0, (%A0)+
  move.w %D0, (%A0)+
  dbra   %D1, _roadpalette_loop

  /* Set road palette to background color */
  move.w #0x0842, %D0

.ifdef HAVE_SUBCPU
  cmp.l #0xEFC2014, _magic_value /* bootloader */
  beq _bgcolor_set
  
  move.w #0x0824, %D0 /* Purplish blue */
  cmp.l #0xEFC2017, _magic_value /* memtest */
  beq _bgcolor_set
  
  # Nothing interesting found.
  move.w #0x0666, %D0 /* Pick a dreary color here */
.endif /* HAVE_SUBCPU */
  
_bgcolor_set:
  move.l #(PALETTE_BASE+(0x2F00)), %A0 /*0x122F00*/
  move.w %D0, (%A0)+ /* Set Background Colour */
  
  /* Init text palette */
  move.l #_textpalette_end, %D0
  sub.l #_textpalette, %D0
  lsr.l #1, %D0
  subq.l #1, %D0 /* Number of colors - 1 */  
  move.l #_textpalette, %A0
  move.l #PALETTE_BASE+(0x3800), %A1
  
_textpalette_loop:
  move.w (%A0)+, (%A1)+
  dbra %D0, _textpalette_loop
  
  RETURN

# Init/restore tile map.
.global InitTile
InitTile:
  /* Set and clear one tile map (#0) */
  clr.w TILE_REGISTERS
  clr.w TILE_REGISTERS+2
  move.w #0x3ff, %D0
  move.l #0x00200020, %D1
  move.l #TILERAM_BASE, %A0
_tileclear_loop:
  move.l %D1, (%A0)+
  dbra %D0, _tileclear_loop

  WATCHDOG_CLEAR
  
  /* Reset all tile registers; this also sets the tile maps to use map #0 (which we just cleared) */
  move.w #0x5e, %D0
  move.l #TILE_REGISTERS, %A0
 _tilereg_loop:
  clr.l (%A0)+
  dbra %D0, _tilereg_loop
  RETURN

# Save text contents to tile memory.
.global SaveText
SaveText:
  move.w #((TEXT_WIDTH*TEXT_HEIGHT)-1), %D0
  move.l #TEXTRAM_BASE, %A0
  move.l #TILERAM_BASE, %A1 /* We could actually just use an invisible page for this */
_savetext_loop:
  move.w (%A0)+, (%A1)+
  dbra %D0, _savetext_loop
  sub.l #TEXTRAM_BASE, %A4
  add.l #TILERAM_BASE, %A4
  RETURN
  
# Restore text contents to text memory.
.global RestoreText
RestoreText:
  move.w #((TEXT_WIDTH*TEXT_HEIGHT)-1), %D0
  move.l #TILERAM_BASE, %A0
  move.l #TEXTRAM_BASE, %A1
_restoretext_loop:
  move.w (%A0)+, (%A1)+
  dbra %D0, _restoretext_loop
  sub.l #TILERAM_BASE, %A4
  add.l #TEXTRAM_BASE, %A4

  WATCHDOG_CLEAR
  jmp InitTile /* Also clear out tile ram now */
  
/* ------------------------------------------------------------------------------------------------
   Entry point. Assume interrupts disabled and in supervisor mode.
   ------------------------------------------------------------------------------------------------ */
.text
.global _start
_start:

/* Configure X-Board I/O */
  move.w #3,    IO1_REG1                   /* Port A = Input, Rest set to outputs */
  move.b #0,    IO1_PORTD                  /* Mute Amp */
  move.w #0xFF, (IO2_BASE)+0xC
  move.w #1,    IO_CTRL
  move.b #0x88, IO1_PORTB                             

.ifdef HAVE_SUBCPU
  CALL ResetSubCPU
.endif

  /*WATCHDOG_CLEAR*/
  
  DISABLE_SCREEN
  DIGITAL_RESET

  move.l #0xc0000000, SPRITE_BASE
  clr.l (SPRITE_BASE+0x4)
  clr.l (SPRITE_BASE+0x8)
  clr.l (SPRITE_BASE+0xc)
  FLIP_SPRITES

    
  CALL EnableIRQ4
  CALL SwapRoad       /* Initalize First Half of Road RAM */
  move.w #0x2700, %SR /* Disable interrupts */
  CALL InitPalette

  WATCHDOG_CLEAR
  
  /* Clear text layer */
  move.l #0x00200020, %D0
  move.w #0x37f, %D1
  move.l #TEXTRAM_BASE, %A0
_textclear_loop:
  move.l %D0, (%A0)+
  dbra   %D1, _textclear_loop

  WATCHDOG_CLEAR

  CALL InitTile
  
  /*WATCHDOG_CLEAR*/

  /* Enable the screen */
  ENABLE_SCREEN

  /* Print header */  
  # Text starting position. We'll keep that in A4 !!
  move.l #(TEXTRAM_BASE+((TEXT_INDENT+(1*TEXT_WIDTH))*2)), %A4
  PRINT _str_titlemessage, COLOR_CYAN
  NEWLINE 
  NEWLINE

  WATCHDOG_CLEAR

  /* Here we have the main loop of testing memory.
     We'll be going through a list of RAM chips to test and print the results.
	 After each test we can have a custom callback in order to restore anything we messed up during the test. */
  
  # Store pointer to current entry of our RAM list.
  .global ramInfo
  move.l #ramInfo, %A5
  
  # From here on, plz do not trash either A5 (current test) or A4 (text cursor)
  
_memtest_loop:
  
  tst.l (%A5)
  beq _memtest_done /* null pointer test; if the name is nullptr, we're done testing */

  /* Print the IC name */  
  move.l (%A5)+, %A0
  move.w #COLOR_YELLOW, %D0
  CALL(_print)
  
  /* Test data bus */
  PRINT _str_db, COLOR_WHITE
  move.l (%A5)+, %A0 /* Param for memTestDataBus */
  # a5 = +8
  add.l #10, %A5

_memtest_db_local:
  CALL memTestDataBus8Asm /* Result in D0; nonzero means failure */
_memtest_db_done:

  sub.l #18, %A5
  tst.b %D0
  beq _memtest_db_ok
  
  /* Data bus failed */
  move.b %D0, %D1
  PRINT _str_error, COLOR_RED
  move.b %D1, %D0
  CALL _printhex2
  jmp _memtest_fail
  
_memtest_db_ok:
  WATCHDOG_CLEAR
  PRINT _str_ok, COLOR_GREEN 
  PRINT _str_ab, COLOR_WHITE
  
  /* Test address bus */
  addq.l #4, %A5
  move.l (%A5), %A0 /* Address */
  addq.l #6, %A5
  move.l (%A5), %D0 /* Size */
  move.l #2, %D1    /* Offset = 2 */
  add.l #8, %A5

_memtest_ab_local:
  CALL memTestAddressBusAsm
_memtest_ab_done:

  sub.l #18, %A5

  move.l %A0, %D0
  tst.l %D0
  beq _memtest_ab_ok

  /* Address bus failed */
_memtest_fail_a0: /* reused for device */
  move.l %D0, %D1
  PRINT _str_error, COLOR_RED
  move.l %D1, %D0
  CALL _printhex6

_memtest_fail:
  DIGITAL_FAIL
  move.l #1000, %D0
  CALL(_sleep);
  
  jmp _memtest_next
  
_memtest_ab_ok:
  WATCHDOG_CLEAR
  PRINT _str_ok, COLOR_GREEN  
  PRINT _str_dev, COLOR_WHITE
  
  /* Full region test. This will result in garbage on screen for some tests. */
  addq.l #4, %A5
  move.l (%A5), %A0 /* Address */
  addq.l #6, %A5
  move.l (%A5), %D0 /* Size */
  subq.l #2, %A5 
  clr.l %D1
  move.w (%A5), %D1 /* Interleave */
  add.l #10, %A5

_memtest_dev_local:
  CALL memTestDeviceAsm
_memtest_dev_done:
  
  sub.l #18, %A5
  move.l %A0, %D0
  tst.l %D0
  beq _memtest_dev_ok
  jmp _memtest_fail_a0
  
_memtest_dev_ok:
  PRINT _str_ok, COLOR_GREEN  
  WATCHDOG_CLEAR

  /* IC is entirely good! */
  DIGITAL_OK
  move.l #500, %D0
  CALL(_sleep);

.global _memtest_next  
_memtest_next:  

  # Optional restoration callback.
  add.l #14, %A5
  tst.l (%A5)
  beq _memtest_nocb

_memtest_localcb:
  move.l #_memtest_nocb, %A6
  move.l (%A5), %A0
  jmp (%A0) /* needed for indirect jump */
_memtest_nocb:
  sub.l #14, %A5 /* Already -4 */

  # Wait another 300ms after the lights go out, that way we can always the results apart.
  DIGITAL_RESET
  move.l #300, %D0
  CALL _sleep
  
  /* Next test */
  NEWLINE
  add.l #20, %A5  /* add sizeof(struct RAMREGION) */
  jmp _memtest_loop
    
_memtest_done:
    # -------------------------------------------------------------------------
    # Test Customs
    # -------------------------------------------------------------------------
    clr.l   %d7                     /* Clear stored seed for random */
    
    # 2E0000-2E3FFF : Hardware multiplier (315-5248, IC30). Actually IC37 on the PCB, AfterBurner gets this wrong. 
    WATCHDOG_CLEAR
    PRINT   _str_ic37, COLOR_YELLOW
    lea     HW_DIVIDE2, %a0         /* Yes this is correct, the test function uses an offset */
    CALL_A5 testMultiplier
    tst.w   %d0
    beq     _custom1_ok
    PRINT   _str_error, COLOR_RED
    bra     _custom2
_custom1_ok:
    PRINT   _str_ok, COLOR_GREEN
    
    # 2E4000-2E7FFF : Hardware divider (315-5249, IC37). Actually IC41 on the PCB, AfterBurner gets this wrong.
_custom2:
    WATCHDOG_CLEAR
    PRINT   _str_ic41, COLOR_YELLOW
    lea     HW_DIVIDE2, %a0
    CALL_A5 testDivider
    tst.w   %d0
    beq     _custom2_ok
    PRINT   _str_error, COLOR_RED
    bra     _custom3
_custom2_ok:
    PRINT   _str_ok, COLOR_GREEN
    
    # 2E8000-2EBFFF : Hardware comparator (315-5250, IC53)
_custom3:
    WATCHDOG_CLEAR
    PRINT   _str_ic53, COLOR_YELLOW
    lea     HW_DIVIDE1, %a0
    CALL_A5 testComparator
    tst.w   %d0
    beq     _custom3_ok
    PRINT   _str_error, COLOR_RED
    bra     _custom4
_custom3_ok:
    PRINT   _str_ok, COLOR_GREEN
  
# 0E0000-0E3FFF : Hardware multiplier (315-5248, IC107)  
_custom4:
    WATCHDOG_CLEAR
    NEWLINE
    PRINT   _str_ic107, COLOR_YELLOW
    lea     HW_DIVIDE1, %a0
    CALL_A5 testMultiplier
    tst.w   %d0
    beq     _custom4_ok
    PRINT   _str_error, COLOR_RED
    bra     _custom5
_custom4_ok:
    PRINT   _str_ok, COLOR_GREEN
    
# 0E4000-0E7FFF : Hardware divider    (315-5249, IC108)   
_custom5:
    WATCHDOG_CLEAR
    PRINT   _str_ic108, COLOR_YELLOW
    lea     HW_DIVIDE1, %a0
    CALL_A5 testDivider
    tst.w   %d0
    beq     _custom5_ok
    PRINT   _str_error, COLOR_RED
    bra     _reboot
_custom5_ok:
    PRINT   _str_ok, COLOR_GREEN

  # -------------------------------------------------------------------------
  # Rebooting in 9... and so on.
  # -------------------------------------------------------------------------
_reboot:
  NEWLINE
  NEWLINE
  PRINT _str_reboot, COLOR_RED
  subq.l #8, %A4      /* Set cursor pos right on the '9' */

  move.w #8, %D2
_restart_countdown:  
  move.l #1000, %D0
  CALL(_sleep);       /* You should think about it, take a second. */
  subq.w #1, (%A4)
  dbra %D2, _restart_countdown
  
  # Done waiting, reboot.
  
/*
  Reboots to the image in ROM.
*/
_rebootrom:

  move.w #0x2700, %SR /* Disable interrupts */
.ifdef HAVE_SUBCPU
  CALL ResetSubCPU
.endif

  move.w #0x003, %D0 /* Screen to red */
  CALL _bgcolor_set

  /* Sleep 500ms, but without resetting the watchdog. On a real board, with the watchdog in place, it will time out way faster than this. */
  move.w #500, %D0
_sleep_reboot:
  move.w #1000, %D1 /* dbra is ~12 cycles, so this should be about one millisecond */
_sleep_1ms_reboot:
  dbra %D1, _sleep_1ms_reboot
  dbra %D0, _sleep_reboot
  
  /* The old fashioned way */
  jmp _start;
  
/* 
   Sleep function; D0 = amount of milliseconds (approximately); A6 = return address.
   Modifies D0 and D1
*/
_sleep:
  move.w #1000, %D1 /* dbra is ~12 cycles, so this should be about one millisecond */
_sleep_one_ms:
  dbra %D1, _sleep_one_ms
  WATCHDOG_CLEAR
  dbra %D0, _sleep
  RETURN

# Dummy IRQ routine.
.global _dummyirq
_dummyirq:
  rte

# Vertical blank handler.
# This will do an auto watchdog clear; and clear a timer.
# It's intended to take at least the entire scanline.
.global _vblankirq
_vblankirq:
  clr.b _vblank_wait_flag

.ifdef CPU0
  WATCHDOG_CLEAR
.endif

  /* Wait out the rest of the scanline so the interrupt doesn't trigger twice.
     we have 262 scanlines @ 60fps = 15720 scanlines per second. So one scanline is 636.1 cycles @ 10Mhz.
     Since dbra takes at least 10 cycles, we can loop 64x to waste at least 640 cycles */
  move.l   %D0, -(%SP)
  move.w   #((CYCLES_PER_SCANLINE+9)/10), %D0
_irq4_wait:
  dbra     %D0, _irq4_wait
  /* We are now at scanline 224 (invisible) */
  move.l   (%SP)+, %D0

  rte

.global EnableIRQ4
EnableIRQ4:
  move.l #_stack_super, %A7 /* The supervisor stack pointer needs to be valid! Assumes we are still in supervisor mode. */
  move.w #0x2300, %SR
  RETURN
  
# Miscellaneous data, written to ROM.
.section .rodata

_str_reboot:
.asciz "RESTARTING IN 9..."
_str_error:
.asciz " ERR "
_str_ok:
.asciz " OK"
_str_ab:
.asciz " AB"
_str_db:
.asciz " DB"
_str_dev:
.asciz " DEV"
_str_ic37:
.asciz "CUSTOMS IC37 "
_str_ic41:
.asciz " IC41 "
_str_ic53:
.asciz " IC53 "
_str_ic107:
.asciz "CUSTOMS IC107"
_str_ic108:
.asciz " IC108"

.section .data

/* IRQ timer ack */
_vblank_wait_flag: 
.skip 1 
