# Boot ROM and a Bootloader

The objective of this project was to gain an understanding of the boot process of an operating system by utilizing QEMU and creating a custom bootloader for the xv6 OS kernel. The bootloader was designed to perform four essential tasks. Firstly, it would load onto the machine before the OS initialization and facilitate the execution of C code. Secondly, it would configure the hardware settings to ensure accurate OS operation. Thirdly, it would load the correct OS based on the user's provided configuration. Finally, it would provide the OS with the system's configuration information, such as the starting address of the bootloader binary.

## A. Installing xv6 pre-requisites (OPTIONAL)

Please skip this step if you've already completed assignment #0. Reach out to the TAs if you have any installation issues or use the Apporto Cloud VMs.

### Linux/WSL

1. Navigate to the install/linux-wsl folder
2. Install RISC-V QEMU: `./linux-qemu.sh`
3. Install RISC-V toolchain:`./linux-toolchain.sh`
4. Add installed binaries to path: `source .add-linux-paths`

### MacOS

1. Navigate to the install/mac folder
2. Install RISC-V QEMU: `./mac-qemu.sh`
3. Install RISC-V toolchain: `./mac-toolchain.sh`
4. Add installed binaries to path: `source .add-mac-paths`

## B. Running the Bootloader

Navigate to main folder and run `make qemu`

## Bootloader Linker Script and Boot into Assembly
The linker descriptor has been written in the file bootloader/bootloader.ld. The following steps were followed:
• The starting address of the bootloader binary was specified as bootloader-start.
• Different sections of the bootloader were placed in the following order: .text, .data, .rodata, and .bss.
• The ending addresses of each section and the bootloader binary were specified in the following variables:
    ecode: end of code (or text) section
    edata: end of data section
    erodata: end of the read-only data section
    ebss: end of the global or bss section
    end: end of the binary program. The first suggested reading was referred to in order to understand program sections.

## Stack setup
The stack is pre-allocated using the variable bl_stack (in the file bootloader/start.c). The task has been completed. The following steps were taken in entry.S:
• The address of bl_stack was loaded into the RISC-V stack pointer register (sp), which is a per-CPU register. The end of bl_stack was loaded as stack is used from high to low.
• After loading the stack, the code jumped to the C function start in bootloader/start.c.

## Setup the RISC-V PMP
The aim was to setup PMP to allow S-mode access to all physical memory of the machine, except for the higher 10 megabytes (MBs) has been completed.

The following steps were performed:
• The RISC-V CPU manual was read to understand PMP, including the bits of pmpcfg0 and how to specify the memory address in pmpaddr0.
• pmpcfg0 register was set up with read, write, and execute permission bits, and the A field in the register was set to top-of-range (TOR), as specified in Table 3.10 in the RISC-V manual.
• pmpaddr0 register was set up with the highest physical address accessible to the OS.

## Loading of User-Selected OSs functionality
The goal was to set-up the functionality such that any of the provided OS kernel binaries can be run on the system. There are three different kernel binaries (kernel1, kernel2, and kernel3). The machine can be configured to run with either of these kernels using the command make qemu-kernel[1-3].

The code has been written in the function read_kernel_load_addr in the file bootloader/elf.c. To read the headers and determine the starting address(kernload-start) where the kernel should be loaded the steps that were followed are:
• An ELF struct (elfhdr) was pointed to RAMDISK in bootloader/elf.h to initialize it with the kernel binary's ELF header.
• The offset at which program header sections are specified (field phoff in the elfhdr) within the kernel binary and the size of the program headers (field phsize in the elfhdr) were grabbed.
• A program header struct (proghdr) was pointed to the second address of the program header section. This is the header for the .text section and its address is RAMDISK + phoff + phsize. This was done to initialize it with the .text section's header.
• The starting address of the .text section was found by retrieving the vaddr field within proghdr.

The following steps have been completed to copy the kernel binary to kernload-start:
• The size of the kernel binary was found using its ELF headers in find_kernel_size (located in bootloader/elf.c).
• In bootloader/load.c, the function kernel_copy was used to copy the kernel binary (currently at RAMDISK) to other memory regions. The function accepts a buf struct (defined in bootloader/buf.h) as an argument.
• In start, the function kernel_copy was used to copy the kernel binary to kernload-start, excluding the kernel headers.

The code to jump to the entry function in the kernel has been written. Here's a summary of the steps taken:
• The function find_kernel_entry_addr in bootloader/elf.c was used to find the kernel entry function address, which is specified in the kernel ELF header.
• In the start function, the kernel entry function address was specified in the mepc register using the CSRRW instruction.
• The mret instruction was then executed to switch the system privilege into S-mode, which will jump to the location specified in the mepc register.

## System Information for the Kernel 4
The struct sys_info has been created and populated with the necessary information at SYSINFOADDR (0x80080000). The following steps were taken:

• A struct sys_info was defined in bootloader/start.c that points to SYSINFOADDR (0x80080000).
• The starting and ending address of the bootloader were specified in the struct.
• The starting and ending address of the DRAM were specified in the struct.
• Three new functions were written in bootloader/riscv.h: r_vendor, r_architecture, and r_implementation. These functions read the vendor ID, architectural ID, and implementation ID from RISC-V system registers.

## Acknowledgement

The xv6 Operating System is used. xv6 is a teaching-focused OS designed by some incredible folks at MIT ([link](https://github.com/mit-pdos/xv6-riscv.git)). 