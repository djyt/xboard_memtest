/* 
   Memory test sub program for Sega Out Run.
   Road flip address is hardcoded. Could be a RPC param.
*/   

.include "config.inc"
.include "ramless.inc"
.include "shared.inc"

.macro WAIT_VBLANK
  bset #0, _vblank_wait_flag
1:
  tst.b _vblank_wait_flag
  bne 1b
.endm

/*
   Entry point.
*/
.text
.global _start
_start:
  clr.l SUB_Magic

_nextcommand:
  /* Set a magic value so the main CPU knows the correct roms are present */  
  move.l #MAGIC_MEMTEST_SUB, _magic_value
  clr.l SUB_Function_Busy
_waitcommand:
  cmp.l #MAGIC_RPC_START, SUB_Magic
  bne _waitcommand
  
  move.l #2, SUB_Function_Busy
  clr.l SUB_Magic

  move.l SUB_Function, %D0
  lsl.l #2, %D0
  move.l #_functiontable, %A0
  move.l (%D0, %A0), %A5
  
  move.l SUB_Function_A0, %A0
  move.l SUB_Function_D0, %D0
  move.l SUB_Function_D1, %D1
  
  CALL (%A5)
    
  move.l %D0, SUB_Function_D0
  move.l %A0, SUB_Function_A0
  jmp _nextcommand



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

# RPC functions.
_functiontable:
  .long memTestDataBus8Asm
  .long memTestAddressBusAsm
  .long memTestDeviceAsm
  
  # Add new functions here.

.section .data

/* IRQ timer ack */
_vblank_wait_flag: 
.skip 1 
