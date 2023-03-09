/* These files have been taken from the open-source xv6 Operating System codebase (MIT License).  */
/* Modifications made by Adil Ahmad. */

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"
#include "buf.h"

void main();
void timerinit();

// entry.S needs one stack per CPU.
__attribute__ ((aligned (16))) char bl_stack[STSIZE * NCPU];

// Task: Collect and store hardware information
struct sys_info {
  // HW info collected from CPU registers
  uint64 vendor;
  uint64 arch;
  uint64 impl;

  // Bootloader binary addresses
  uint64 bl_start;
  uint64 bl_end;

  // Accessible DRAM addresses
  uint64 dr_start;
  uint64 dr_end;
};
struct sys_info* sys_info_ptr;

extern void _entry(void);

// entry.S jumps here in machine mode on stack0.
void
start()
{
  // keep each CPU's hartid in its tp register, for cpuid().
  int id = r_mhartid();
  w_tp(id);

  // set M Previous Privilege mode to Supervisor, for mret.
  unsigned long x = r_mstatus();
  // MSTATUS_MPP_MASK 3 << 11=>   0001 1000 0000 0000 => 6144
  // Then negation           .... 1110 0111 1111 1111 ANDing it with MSTATUS
  // MSTATUS_MPP_S   1 << 11 =>   0000 1000 0000 0000 => 2048 ORing with x which is Zero and writing it to mstatus            
  x &= ~MSTATUS_MPP_MASK;
  x |= MSTATUS_MPP_S;
  w_mstatus(x);

  // disable paging for now.
  w_satp(0);

  // delegate all interrupts and exceptions to supervisor mode.
  w_medeleg(0xffff);
  w_mideleg(0xffff);
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);

  // CSE 536: Task 2.4
  //  Enable R/W/X access to all parts of the address space, 
  //  except for the upper 10 MB (0 - 117 MB) using PMP
  w_pmpaddr0(0x21D40000ull);
  w_pmpcfg0(0xf);

  // CSE 536: Task 2.5
  // Load the kernel binary to its correct location
  uint64 kernel_entry_addr = 0;
  uint64 kernel_load_addr  = 0;
  uint64 kernel_size       = 0;

  // CSE 536: Task 2.5.1
  // Find the loading address of the kernel binary
  // .text starting address
  kernel_load_addr  = find_kernel_load_addr();

  // CSE 536: Task 2.5.2
  // Find the kernel binary size and copy it to the load address
  // Total file size
  kernel_size       = find_kernel_size();
  // Copying without headers
  // write into kernel_load_addr = entry header of xv6, reading from kernel's .text = RAMDISK + 4096
  memmove((int *)kernel_load_addr,(int *)(RAMDISK + 4096), kernel_size - 4096);
  
  // CSE 536: Task 2.5.34096
  // Find the entry address and write it to mepc
  kernel_entry_addr = find_kernel_entry_addr();

  w_mepc(kernel_entry_addr);
  
  // CSE 536: Task 2.6
  // Provide system information to the kernel
  sys_info_ptr = (struct sys_info *)0x80080000;
  // Info collected from CPU registers
  sys_info_ptr->vendor = r_vendor();
  sys_info_ptr->arch = r_architecture();
  sys_info_ptr->impl = r_implementation();
  // Info collected from Bootloader binary addresses
  sys_info_ptr->bl_start = 0x80000000;
  sys_info_ptr->bl_end = end;
  // // Accessible DRAM addresses //  except for the upper 10 MB (0 - 117 MB)
  sys_info_ptr->dr_start = 0x80000000;
  // //(KERNBASE + 128*1024*1024) = 2270167040 which is 0x87500000
  sys_info_ptr->dr_end =  PHYSTOP;
  // CSE 536: Task 2.5.3
  // switch to supervisor mode and jum0x87600000p to main().
  // Jump to the OS kernel code
  asm volatile("mret");
}