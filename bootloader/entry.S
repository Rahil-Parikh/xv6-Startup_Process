# _entry should be the first function invoked when
# the QEMU CPU starts executing. 

.section .text
.global _entry
_entry:
        # CSE 536: Task 2.3
        # Load the end of bl_stack to the sp register
        la sp, bl_stack
        # Size of bl_stack per-CPU is 4096
        li a0, 1024*4
        #  mhartid CSR is an MXLEN-bit read-only register containing the integer ID of the hardware thread running the code
        csrr a1, mhartid
        # starts with hart ID zero.
        addi a1, a1, 1
        # starting address of bl_stack per-CPU
        mul a0, a0, a1
        # bl_stack is used from high to low; hence, load the end of bl_stack in sp
        add sp, sp, a0
        # jump to start() in start.c
        call start
.global spin
spin:
        j spin