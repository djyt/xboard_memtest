/* 
	Sega X-Board memory test linker script.
*/

OUTPUT_ARCH(m68k)
OUTPUT_FORMAT(binary)
__DYNAMIC  =  0; 

MEMORY
{
	rom (rx)    : ORIGIN = 0x00000000, LENGTH = 512K
	ram (rwx)   : ORIGIN = 0x00080000, LENGTH = 16K  /* Only use bottom half for stack & irq ack */
	subram (rw) : ORIGIN = 0x00280000, LENGTH = 256
}

PROVIDE (_stack_super = 0x00084000);

ENTRY(_start);

SECTIONS 
{
	. = 0x00000000;
	.text :
	{
		LONG(_stack_super); /* Stack pointer */
		LONG(_start);       /* Reset initial program counter */

		/* Here come all the other vectors:
		   08 Access fault
		   0c Address error
		   10 Illegal instruction
		   14 Integer division by zero
		   18 CHK, CHK2 Instruction
		   1C FTRAPcc, TRAPcc, TRAPV instructions.
		   20 Privilige violation.
		   24 Trace.
		   28 Line 1010 Emulator
		   2C Line 1111 Emulator
		   30 Unassigned, reserved.
		   34 Coprocessor protocol violation.
		   38 Format error.
		   3c Uninitialized interrupt.
		*/

		/* Interrupt table. */
		. = 0x60;
		LONG(_dummyirq);
		LONG(_dummyirq); /* Level 1 */
		LONG(_dummyirq);
		LONG(_dummyirq);
		LONG(_vblankirq); /* 4 */
		LONG(_dummyirq);
		LONG(_dummyirq);
		LONG(_dummyirq); /* Level 7 */

		. = 0x80; /* User Trap Vectors */
		LONG(_dummyirq);
		LONG(_dummyirq);
		LONG(_dummyirq);
		LONG(_dummyirq);
		LONG(_dummyirq);
		LONG(_dummyirq);
		LONG(_dummyirq);
		LONG(_dummyirq);
		LONG(_dummyirq);
		LONG(_dummyirq);
		LONG(_dummyirq);
		LONG(_dummyirq);
		LONG(_dummyirq);
		LONG(_dummyirq);
		LONG(_dummyirq);
		LONG(_dummyirq);

		. = 0x100;
		*(.text .text.*)

		. = ALIGN(2);
		*(.rodata .rodata.*)
	} > rom

	.data (NOLOAD) :
	{
		. = ALIGN (0x2);
		__data_start = .;

		*(.data .data.*)

		. = ALIGN (2);
		__data_end = .;

	} > ram
	
	/* Secondary CPU ram */	
	.subdata (NOLOAD) : 
	{
		_sub_sp = .;      /* stack pointer */
		. = . + 4;
		_sub_pc = .;      /* program counter */

		. = 0xefc;
		_magic_value = .; /* magic value for the sub CPU, to detect whether we have the right roms */
		. = . + 4;
		
		/* Shared data (memory test parameters) */
		. = ALIGN(2);
		*(.shared .shared.*)
				
	} > subram 

}
