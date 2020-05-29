# Assembler implementation of the functions in memtest.c
# They can either have 'regular' C calling convention (params/return address on stack, return value in D0), 
# or our 'ramless' calling convention: everything in registers; return to (A6).

# Based on http://www.esacademy.com/en/library/technical-articles-and-documents/miscellaneous/software-based-memory-testing.html
#   Copyright (c) 2000 by Michael Barr
#   "This article shows how to test for the most common memory problems with a set of three efficient, portable, public-domain memory test functions."
#   This article is adapted from material in Chapter 6 of the book Programming Embedded Systems in C and C++ (ISBN 1-56592-354-5). It is printed here with the permission of O'Reilly & Associates, Inc.

# Use this to generate C callable (cdecl) code. That way it's directly compatible with memtest.c.
# .set HAVE_C_VERSIONS, 1

.include "config.inc"
.include "io.inc"
.include "ramless.inc"

.equ PATTERN, 0xaa
.equ ANTIPATTERN, 0x55

/**********************************************************************
 *
 * Function:    memTestDataBus()
 *
 * Description: Test the data bus wiring in a memory region by
 *              performing a walking 1's test at a fixed address
 *              within that region.  The address (and hence the
 *              memory region) is selected by the caller.
 *
 * Returns:     0 if the test succeeds.  
 *              A non-zero result is the first pattern that failed.
 *
 **********************************************************************/

# unsigned char
# memTestDataBus8(volatile unsigned char * address)
# {
#     unsigned char pattern;
#     /*
#      * Perform a walking 1's test at the given address.
#      */
#     for (pattern = 1; pattern != 0; pattern <<= 1)
#     {
#         /*
#          * Write the test pattern.
#          */
#         *address = pattern;
#         /*
#          * Read it back (immediately is okay for this test).
#          */
#         if (*address != pattern)
#         {
#             return (pattern);
#         }
#     }
#     return (0);
# }   /* memTestDataBus8() */

# unsigned char memTestDataBus8(volatile unsigned char* address);

# A0 = address to test at. should not be in use.
# D0.b = return value. 0 = ok; nonzero = bit that failed.
# Modifies D1.b; flags.

.global memTestDataBus8Asm
memTestDataBus8Asm:

  # Perform a walking 1's test at the given address.
  move.b #1, %D0    /* initial pattern */
db_loop:
  move.b %D0, (%A0) /* write to destination */
  move.b (%A0), %D1 /* read back into D1 */
  cmp.b  %D0, %D1
  bne db_end
  lsl.b #1, %D0     /* pattern <<= 1 */   
  bne db_loop
  /* (byte)D0 == 0 */
db_end: 

  RETURN
  
# cdecl version.

.ifdef HAVE_C_VERSIONS

.global memTestDataBus8
memTestDataBus8:
  move.l (0x4, %SP), %A0                /* Read parameter from the stack */
  move.l %A6, -(%SP)					/* Store A6 */
  CALL(memTestDataBus8Asm)              /* "Call" */
  move.l (%SP)+, %A6					/* Restore A6 */
  rts
  
.endif
  
/**********************************************************************
 *
 * Function:    memTestAddressBus()
 *
 * Description: Test the address bus wiring in a memory region by
 *              performing a walking 1's test on the relevant bits
 *              of the address and checking for aliasing. This test
 *              will find single-bit address failures such as stuck
 *              -high, stuck-low, and shorted pins.  The base address
 *              and size of the region are selected by the caller.
 *
 * Notes:       For best results, the selected base address should
 *              have enough LSB 0's to guarantee single address bit
 *              changes.  For example, to test a 64-Kbyte region,
 *              select a base address on a 64-Kbyte boundary.  Also,
 *              select the region size as a power-of-two--if at all
 *              possible.
 *
 * Returns:     NULL if the test succeeds.  
 *              A non-zero result is the first address at which an
 *              aliasing problem was uncovered.  By examining the
 *              contents of memory, it may be possible to gather
 *              additional information about the problem.
 *
 **********************************************************************/
# startOffset should be 2 if we're doing split 16 bit databus checks, and 1 for 8 bit checks.

# datum* memTestAddressBus(volatile datum* baseAddress, unsigned long nBytes, unsigned long startOffset);

# A0 = baseAddress
# D0 = nBytes
# D1 = startOffset
# modify D0, D2, D3, D4, flags
# return value in A0

.global memTestAddressBusAsm
memTestAddressBusAsm:

  # unsigned long addressMask = (nBytes/sizeof(datum) - 1);

  subq.l #1, %D0       		  /* nBytes-1 */

  # /*
  #  * Write the default pattern at each of the power-of-two offsets.
  #  */
  # for (offset = startOffset; (offset & addressMask) != 0; offset <<= 1)
  #     baseAddress[offset] = pattern;

  move.l %D1, %D2             /* offset = startOffset */
  
ab_loop1:
  move.b #PATTERN, (%D2, %A0) /* baseAddress[offset] = pattern */
  lsl.l #1, %D2               /* offset <<= 1 */
  move.l %D2, %D3
  and.l %D0, %D3              /* test (offset&addressmask) */
  bne ab_loop1

  # /*
  #  * Check for address bits stuck high.
  #  */
  # testOffset = 0;
  # baseAddress[testOffset] = antipattern;
  # for (offset = startOffset; (offset & addressMask) != 0; offset <<= 1)
  # {
  #     if (baseAddress[offset] != pattern)
  #         return ((datum *) &baseAddress[offset]);
  # }
  # baseAddress[testOffset] = pattern;

  move.b #ANTIPATTERN, (%A0)  /* baseAddress[offset] = antipattern */

  move.l %D1, %D2             /* offset = startOffset */
ab_loop2:
  cmp.b #PATTERN, (%D2, %A0)  /* test against pattern, which should still be there */
  beq ab_loop2_next
  
  /* MISMATCH: byte not matching pattern! */
  add.l %D2, %A0              /* return value in A0 (address with wrong data) */
  jmp ab_end

ab_loop2_next:
  lsl.l #1, %D2               /* offset <<= 1 */
  move.l %D2, %D3
  and.l %D0, %D3              /* test (offset&addressmask) */
  bne ab_loop2
  
  move.b #PATTERN, (%A0)      /* baseAddress[offset] = pattern */

  # /*
  #  * Check for address bits stuck low or shorted.
  #  */
  # for (testOffset = startOffset; (testOffset & addressMask) != 0; testOffset <<= 1)
  # {
  #     baseAddress[testOffset] = antipattern;
  #     if (baseAddress[0] != pattern)
  #         return ((datum *) &baseAddress[testOffset]);
  #
  #     for (offset = startOffset; (offset & addressMask) != 0; offset <<= 1)
  #     {
  #         if ((baseAddress[offset] != pattern) && (offset != testOffset))
  #             return ((datum *) &baseAddress[testOffset]);
  #     }
  #     baseAddress[testOffset] = pattern;
  # }
  
  move.l %D1, %D2                 /* testOffset = startOffset */
ab_loop3:
  move.b #ANTIPATTERN, (%D2, %A0) /* baseAddress[testOffset] = antipattern */
  cmp.b #PATTERN, (%A0)
  beq ab_loop3_good1

  /* MISMATCH; address in A0 */
  add.l %D2, %A0
  jmp ab_end
  
ab_loop3_good1:
  
  /* inner loop */
  move.l %D1, %D3                 /* offset = startOffset */
ab_loop3_inner:

  cmp.b #PATTERN, (%D3, %A0)
  beq ab_loop3_inner_good
  cmp.l %D3, %D2
  beq ab_loop3_inner_good
  
  /* MISMATCH; address in A0 */
  add.l %D2, %A0 		          /* add testOffset */
  jmp ab_end

ab_loop3_inner_good:

  lsl.l #1, %D3                   /* offset <<= 1 */
  move.l %D3, %D4
  and.l %D0, %D4
  bne ab_loop3_inner
  
  move.b #PATTERN, (%D2, %A0)     /* baseAddress[testOffset] = pattern */
  
  lsl.l #1, %D2                   /* testOffset <<= 1 */
  move.l %D2, %D3
  and.l %D0, %D3
  bne ab_loop3

  /* No failure! */
  move.l #0, %A0                  /* return NULL */
  
ab_end:

  RETURN

# cdecl version.
  
.ifdef HAVE_C_VERSIONS
  
.global memTestAddressBus
memTestAddressBus:

  /* Read params from stack and store registers */
  move.l (0x4, %SP), %A0
  move.l (0x8, %SP), %D0
  move.l (0xc, %SP), %D1
  move.l %D2, -(%SP)
  move.l %D3, -(%SP)
  move.l %D4, -(%SP)
  move.l %A6, -(%SP)

  CALL(memTestAddressBusAsm)      /* "Call" */

  /* Restore registers */
  move.l %A0, %D0                 /* return value in D0 */
  move.l (%SP)+, %A6
  move.l (%SP)+, %D4
  move.l (%SP)+, %D3
  move.l (%SP)+, %D2

  rts

.endif
  
# /**********************************************************************
#  *
#  * Function:    memTestDevice()
#  *
#  * Description: Test the integrity of a physical memory device by
#  *              performing an increment/decrement test over the
#  *              entire region.  In the process every storage bit
#  *              in the device is tested as a zero and a one.  The
#  *              base address and the size of the region are
#  *              selected by the caller.
#  *
#  * Returns:     NULL if the test succeeds.  Also, in that case, the
#  *              entire memory region will be filled with zeros.
#  *
#  *              A non-zero result is the first address at which an
#  *              incorrect value was read back.  By examining the
#  *              contents of memory, it may be possible to gather
#  *              additional information about the problem.
#  *
#  **********************************************************************/

# datum* memTestDeviceAsm(volatile datum* baseAddress, unsigned long nBytes, unsigned long nSkip);

# A0 = baseAddress
# D0 = nBytes
# D1 = nSkip
# modify D0, D2, D3, flags
# return value in A0

.global memTestDeviceAsm
memTestDeviceAsm:
  
  # /*
  #  * Fill memory with a known pattern.
  #  */
  # for (pattern = 1, offset = 0; offset < nWords; pattern++, offset += nSkip)
  #     baseAddress[offset] = pattern;

  move.b #1, %D3          /* pattern = 1 */
  clr.l %D2               /* offset = 0 */
dev_loop1:
  move.b %D3, (%D2, %A0)  /* *baseAddress = pattern */
  addq.b #1, %D3          /* pattern++ */
  add.l %D1, %D2          /* offset += nSkip */
  cmp.l %D0, %D2
  blt dev_loop1
  
.ifdef CPU0
  WATCHDOG_CLEAR
.endif

  # /*
  #  * Check each location and invert it for the second pass.
  #  */
  # for (pattern = 1, offset = 0; offset < nWords; pattern++, offset += nSkip)
  # {
  #     if (baseAddress[offset] != pattern)
  #         return ((datum *) &baseAddress[offset]);
  #
  #     antipattern = ~pattern;
  #     baseAddress[offset] = antipattern;
  # }
  
  move.b #1, %D3           /* pattern = 1 */
  clr.l %D2                /* offset = 0 */
dev_loop2:

  cmp.b (%D2, %A0), %D3
  beq dev_loop2_good
  
  /* MISMATCH; address in A0 */
  add.l %D2, %A0 		   /* add offset */
  jmp dev_end
  
dev_loop2_good:

  /* write antipattern */
  not.b %D3
  move.b %D3, (%D2, %A0)
  not.b %D3

  addq.b #1, %D3           /* pattern++ */
  add.l %D1, %D2           /* offset += nSkip */
  cmp.l %D0, %D2
  blt dev_loop2

.ifdef CPU0
  WATCHDOG_CLEAR
.endif
  
  # /*
  #  * Check each location for the inverted pattern and zero it.
  #  */
  # for (pattern = 1, offset = 0; offset < nWords; pattern++, offset += nSkip)
  # {
  #     antipattern = ~pattern;
  #     if (baseAddress[offset] != antipattern)
  #         return ((datum *) &baseAddress[offset]);
  # }
  
  move.b #1, %D3           /* pattern = 1 */
  clr.l %D2                /* offset = 0 */
dev_loop3:
  not.b %D3                /* pattern -> antipattern */
  cmp.b (%D2, %A0), %D3
  beq dev_loop3_good

  /* MISMATCH; address in A0 */
  add.l %D2, %A0 		   /* add offset */
  jmp dev_end
  
dev_loop3_good:
  not.b %D3                /* antipattern -> pattern */

  addq.b #1, %D3           /* pattern++ */
  add.l %D1, %D2           /* offset += nSkip */
  cmp.l %D0, %D2
  blt dev_loop3
  
  move.l #0, %A0           /* return NULL */
  
dev_end:

  RETURN
  
# cdecl version.

.ifdef HAVE_C_VERSIONS
  
.global memTestDevice
memTestDevice:

  /* Read params from stack and store registers */
  move.l (0x4, %SP), %A0  /* baseAddress */
  move.l (0x8, %SP), %D0  /* nBytes */
  move.l (0xc, %SP), %D1  /* nSkip */
  move.l %D2, -(%SP)
  move.l %D3, -(%SP)
  move.l %A6, -(%SP)

  CALL(memTestDeviceAsm)          /* "Call" */

  /* Restore registers */
  move.l %A0, %D0                 /* return value in D0 */
  move.l (%SP)+, %A6
  move.l (%SP)+, %D3
  move.l (%SP)+, %D2

  rts  

.endif
