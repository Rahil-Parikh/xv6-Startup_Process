#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"
#include "buf.h"
#include "elf.h"

#include <stdbool.h>

struct elfhdr* kernel_elfhdr;
struct proghdr* kernel_phdr;

uint64 find_kernel_load_addr(void) {
    // CSE 536: task 2.5.1
    //Initializing elfhdr struct (elfhdr) to RAMDISK (where the kernel is currently loaded)
    kernel_elfhdr = RAMDISK;
    //Initializing proghdr struct (proghdr) to RAMDISK + phoff + phentsize
    kernel_phdr = RAMDISK + (*kernel_elfhdr).phoff + (*kernel_elfhdr).phentsize;
    //Returning starting address of the .text section by retrieving the vaddr field within proghdr
    return (*kernel_phdr).vaddr;
}

uint64 find_kernel_size(void) {
    // CSE 536: task 2.5.2
    // riscv64-unknown-elf-readelf -h kernel1
    // Start of section headers + (Size of section headers)*(Number of section headers)
    return (*kernel_elfhdr).shoff + (*kernel_elfhdr).shentsize * (*kernel_elfhdr).shnum;
}

uint64 find_kernel_entry_addr(void) {
    // CSE 536: task 2.5.3
    return (*kernel_elfhdr).entry;
}