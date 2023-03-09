//
// ramdisk that uses the disk image loaded by qemu -initrd fs.img
//

#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "buf.h"

extern void spin(void);

// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
kernel_copy(struct buf *b)
{
  /* Ramdisk is not even reading from the damn file.. */
  if(b->blockno >= FSSIZE)
    spin();

  uint64 diskaddr = b->blockno * BSIZE;
  char *addr = (char *)RAMDISK + diskaddr;

  // read from the location
  memmove(b->data, addr, BSIZE);
}