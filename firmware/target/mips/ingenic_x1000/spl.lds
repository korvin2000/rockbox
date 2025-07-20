#include "config.h"
#include "cpu.h"

#define GCC720 true

#ifdef GCC720
OUTPUT_FORMAT(elf32-tradlittlemips)
#else
OUTPUT_FORMAT(elf32-littlemips)
#endif
OUTPUT_ARCH(MIPS)
ENTRY(_spl_start)
STARTUP(target/mips/ingenic_x1000/spl-start.o)

MEMORY {
    TCSM : ORIGIN = X1000_SPL_EXEC_ADDR,
           LENGTH = X1000_SPL_SIZE
}

SECTIONS
{
    .text :
    {
        *(.init.spl);
        *(.text*);
        *(.icode*);
    } > TCSM

    . = ALIGN(4);
    .rodata :
    {
        *(.rodata*);
    } > TCSM

    . = ALIGN(4);
    .data :
    {
        *(.data*);
        *(.sdata*);
    } > TCSM

    . = ALIGN(4);
    .bss (NOLOAD) :
    {
        _bssbegin = .;
        *(.sbss*);
        *(.bss*);
        *(COMMON);
        *(.scommon*);
        _bssend = .;
    } > TCSM

    /DISCARD/ :
    {
        *(.MIPS.abiflags);
        *(.eh_frame);
        *(.rel.dyn);
    }
}
