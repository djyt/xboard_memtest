.equ MAGIC_BOOTLOADER_SUB, 0xefc2014
.equ MAGIC_MEMTEST_SUB, 0xefc2017
.equ MAGIC_RPC_START, 0x5e9a1986

.section .shared

.align 4
.global SUB_Magic
SUB_Magic:
.skip 4
.global SUB_Function
SUB_Function:
.skip 4
.global SUB_Function_A0
SUB_Function_A0:
.skip 4
.global SUB_Function_D0
SUB_Function_D0:
.skip 4
.global SUB_Function_D1
SUB_Function_D1:
.skip 4
.global SUB_Function_Busy
SUB_Function_Busy:
.skip 4
