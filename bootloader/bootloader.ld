OUTPUT_ARCH( "riscv" )

ENTRY( _entry )

SECTIONS
{
  /* CSE 536: (Task 2.2) Ensure the correct entry address based on where -kernel in QEMU jumps. */
  . = 0x80000000;

  /* CSE 536: (Task 2.2) Keep track of each program section's ending address. text, .data, .rodata, and .bss.*/
  .text : {
    *(.text .text.*)
    . = ALIGN(0x1000);
    PROVIDE(ecode = .);
  }

  .data : {
    . = ALIGN(16);
    *(.data .data.*);
    PROVIDE(edata = .);
  }

  .rodata : {
    . = ALIGN(16);
    *(.rodata .rodata.*)
    PROVIDE(erodata = .);
  }
  
  .bss : {
    . = ALIGN(16);
    *(.bss .bss.*);
    PROVIDE(ebss = .);
  }

  PROVIDE(end = .);
  /* CSE 536: (Task 2.2) Keep track of the binary's ending address. */
}
