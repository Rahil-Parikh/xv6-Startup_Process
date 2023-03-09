B=bootloader
K=kernel
U=user

OBJS = \
  $B/entry.o \
  $B/start.o \
  $B/load.o \
  $B/string.o \
  $B/elf.o

# riscv64-unknown-elf- or riscv64-linux-gnu-
# perhaps in /opt/riscv/bin
#TOOLPREFIX = 

# Try to infer the correct TOOLPREFIX if not set
ifndef TOOLPREFIX
TOOLPREFIX := $(shell if riscv64-unknown-elf-objdump -i 2>&1 | grep 'elf64-big' >/dev/null 2>&1; \
	then echo 'riscv64-unknown-elf-'; \
	elif riscv64-linux-gnu-objdump -i 2>&1 | grep 'elf64-big' >/dev/null 2>&1; \
	then echo 'riscv64-linux-gnu-'; \
	elif riscv64-unknown-linux-gnu-objdump -i 2>&1 | grep 'elf64-big' >/dev/null 2>&1; \
	then echo 'riscv64-unknown-linux-gnu-'; \
	else echo "***" 1>&2; \
	echo "*** Error: Couldn't find a riscv64 version of GCC/binutils." 1>&2; \
	echo "*** To turn off this error, run 'gmake TOOLPREFIX= ...'." 1>&2; \
	echo "***" 1>&2; exit 1; fi)
endif

QEMU = qemu-system-riscv64

CC = $(TOOLPREFIX)gcc
AS = $(TOOLPREFIX)gas
LD = $(TOOLPREFIX)ld
OBJCOPY = $(TOOLPREFIX)objcopy
OBJDUMP = $(TOOLPREFIX)objdump

CFLAGS = -Wall -O0 -fno-omit-frame-pointer -ggdb -gdwarf-2
CFLAGS += -MD
CFLAGS += -mcmodel=medany
CFLAGS += -ffreestanding -fno-common -nostdlib -mno-relax
CFLAGS += -I.
CFLAGS += $(shell $(CC) -fno-stack-protector -E -x c /dev/null >/dev/null 2>&1 && echo -fno-stack-protector)

# Disable PIE when possible (for Ubuntu 16.10 toolchain)
ifneq ($(shell $(CC) -dumpspecs 2>/dev/null | grep -e '[^f]no-pie'),)
CFLAGS += -fno-pie -no-pie
endif
ifneq ($(shell $(CC) -dumpspecs 2>/dev/null | grep -e '[^f]nopie'),)
CFLAGS += -fno-pie -nopie
endif

LDFLAGS = -z max-page-size=4096

# Adil: Creating the bootloader binary
$B/bootloader: $(OBJS) $B/bootloader.ld 
	$(LD) $(LDFLAGS) -T $B/bootloader.ld -o $B/bootloader $(OBJS)
	$(OBJDUMP) -S $B/bootloader > $B/bootloader.asm
	$(OBJDUMP) -t $B/bootloader | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $B/bootloader.sym

tags: $(OBJS) _init
	etags *.S *.c

_%: %.o $(ULIB)
	$(LD) $(LDFLAGS) -T $U/user.ld -o $@ $^
	$(OBJDUMP) -S $@ > $*.asm
	$(OBJDUMP) -t $@ | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $*.sym

# Prevent deletion of intermediate files, e.g. cat.o, after first build, so
# that disk image changes after first build are persistent until clean.  More
# details:
# http://www.gnu.org/software/make/manual/html_node/Chained-Rules.html
.PRECIOUS: %.o

fs.img: mkfs/mkfs README $(UPROGS)
	mkfs/mkfs fs.img README $(UPROGS)

-include kernel/*.d user/*.d

clean: 
	rm -f *.tex *.dvi *.idx *.aux *.log *.ind *.ilg \
	*/*.o */*.d */*.asm */*.sym \
	$U/initcode $U/initcode.out $B/bootloader fs.img \
	mkfs/mkfs .gdbinit \
        $U/usys.S \
	$(UPROGS)

# try to generate a unique GDB port
GDBPORT = $(shell expr `id -u` % 5000 + 25000)
# QEMU's gdb stub command line changed in 0.11
QEMUGDB = $(shell if $(QEMU) -help | grep -q '^-gdb'; \
	then echo "-gdb tcp::$(GDBPORT)"; \
	else echo "-s -p $(GDBPORT)"; fi)
ifndef CPUS
CPUS := 1
endif

QEMUOPTS = -machine virt -bios none -kernel $B/bootloader -m 128M -smp $(CPUS) -nographic
QEMUOPTS1 += -initrd kernel1
QEMUOPTS2 += -initrd kernel2
QEMUOPTS3 += -initrd kernel3
QEMUOPTS4 += -initrd kernel4
QEMUOPTS5 += -initrd kernel-pmp

qemu: kernel2 $B/bootloader
	$(QEMU) $(QEMUOPTS) $(QEMUOPTS1)

qemu-kernel1: kernel1 $B/bootloader
	$(QEMU) $(QEMUOPTS) $(QEMUOPTS1)

qemu-kernel2: kernel2 $B/bootloader
	$(QEMU) $(QEMUOPTS) $(QEMUOPTS2)

qemu-kernel3: kernel3 $B/bootloader
	$(QEMU) $(QEMUOPTS) $(QEMUOPTS3)

qemu-kernel4: kernel4 $B/bootloader
	$(QEMU) $(QEMUOPTS) $(QEMUOPTS4)

qemu-kernel-pmp: kernel-pmp $B/bootloader
	$(QEMU) $(QEMUOPTS) $(QEMUOPTS5)

.gdbinit: .gdbinit.tmpl-riscv
	sed "s/:1234/:$(GDBPORT)/" < $^ > $@

qemu-gdb: $B/bootloader .gdbinit
	@echo "*** Now run 'gdb' in another window." 1>&2
	$(QEMU) $(QEMUOPTS) $(QEMUOPTS1) -S $(QEMUGDB)

run-gdb:
	riscv64-unknown-elf-gdb
