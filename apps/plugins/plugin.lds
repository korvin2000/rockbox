#include "config.h"

/* These output formats should be in the config-files */

#define GCC720 true

#ifdef CPU_COLDFIRE
OUTPUT_FORMAT(elf32-m68k)
#elif defined(CPU_ARM)
OUTPUT_FORMAT(elf32-littlearm)
#elif defined(CPU_MIPS)
#ifdef GCC720
OUTPUT_FORMAT(elf32-tradlittlemips)
#else
OUTPUT_FORMAT(elf32-littlemips)
#endif
#else
/* We can have an #error here we don't use this file when build sims! */
#error Unknown CPU architecture
#endif

#ifdef DEBUG
#define STUBOFFSET 0x10000
#else
#define STUBOFFSET 0
#endif

#if defined(CPU_PP)
#ifdef CPU_PP502x
#define NOCACHE_BASE 	0x10000000
#else
#define NOCACHE_BASE 	0x28000000
#endif /* CPU_* */
#define CACHEALIGN_SIZE 16
#endif /* CPU_PP */

#if CONFIG_CPU==IMX31L
/* No fudges! */
#include "imx31l.h"
#define DRAMSIZE ((MEMORYSIZE * 0x100000) - STUBOFFSET - PLUGIN_BUFFER_SIZE \
                  - CODEC_SIZE - QHARRAY_SIZE - FRAME_SIZE - TTB_SIZE)

#elif CONFIG_CPU==DM320

#ifndef LCD_NATIVE_WIDTH
#define LCD_NATIVE_WIDTH LCD_WIDTH
#endif

#ifndef LCD_NATIVE_HEIGHT
#define LCD_NATIVE_HEIGHT LCD_HEIGHT
#endif

#ifdef MROBE_500
/* Give this 1 meg to allow it to align to the MMU boundary */
#define LCD_FUDGE       LCD_NATIVE_WIDTH%32
#define LCD_BUFFER_SIZE ((LCD_NATIVE_WIDTH+LCD_FUDGE)*LCD_NATIVE_HEIGHT*2)
#define LCD_TTB_AREA    0x100000*((LCD_BUFFER_SIZE>>19)+1)
#else
/* must be 16Kb (0x4000) aligned */
#define TTB_SIZE        (0x4000)
#define LCD_BUFFER_SIZE (LCD_NATIVE_WIDTH*LCD_NATIVE_HEIGHT*2)
#define LCD_TTB_AREA    (TTB_SIZE + LCD_BUFFER_SIZE)
#endif

#define DRAMSIZE (MEMORYSIZE * 0x100000) - STUBOFFSET - PLUGIN_BUFFER_SIZE - CODEC_SIZE - LCD_TTB_AREA

#elif CONFIG_CPU==S3C2440
#include "cpu.h"
/* must be 16Kb (0x4000) aligned */
#define TTB_SIZE         (0x4000)
#define DRAMSIZE (MEMORYSIZE * 0x100000) - STUBOFFSET - PLUGIN_BUFFER_SIZE - CODEC_SIZE - LCD_BUFFER_SIZE - TTB_SIZE

#elif CONFIG_CPU==TCC7801
#include "cpu.h"
#define DRAMSIZE (MEMORYSIZE * 0x100000) - STUBOFFSET - PLUGIN_BUFFER_SIZE - CODEC_SIZE - TTB_SIZE

#elif CONFIG_CPU==AS3525 || CONFIG_CPU==AS3525v2
#include "cpu.h"
#define DRAMORIG DRAM_ORIG
#if defined(AMS_LOWMEM) || (CONFIG_CPU == AS3525v2)
#define DRAMSIZE (DRAM_SIZE - PLUGIN_BUFFER_SIZE - STUBOFFSET - TTB_SIZE)
#else
#define DRAMSIZE (DRAM_SIZE - PLUGIN_BUFFER_SIZE - STUBOFFSET - CODEC_SIZE - TTB_SIZE)
#endif
#elif CONFIG_CPU==S5L8702
#define ASM
#include "cpu.h"
#define DRAMSIZE (DRAM_SIZE - PLUGIN_BUFFER_SIZE - CODEC_SIZE - TTB_SIZE)
#elif CONFIG_CPU==IMX233
#include "cpu.h"
#define DRAMSIZE (DRAM_SIZE - PLUGIN_BUFFER_SIZE - CODEC_SIZE - FRAME_SIZE - TTB_SIZE)
#elif CONFIG_CPU==X1000
#include "cpu.h"
#undef STUBOFFSET
#define DRAMSIZE (X1000_DRAM_SIZE - PLUGIN_BUFFER_SIZE - CODEC_SIZE)
#endif

 /* default to full RAM (minus codecs&plugins) unless specified otherwise */
#ifndef DRAMSIZE
#define DRAMSIZE (MEMORYSIZE * 0x100000) - PLUGIN_BUFFER_SIZE - STUBOFFSET - CODEC_SIZE
#endif

/* MCF5249 have 96KB of IRAM */
#if CONFIG_CPU == MCF5249
#define DRAMORIG 0x31000000
#define IRAMORIG 0x1000c000
#define IRAMSIZE 0xc000

/* MCF5250 have 128KB of IRAM */
#elif CONFIG_CPU == MCF5250
#define DRAMORIG 0x31000000
#define IRAMORIG 0x1000c800
#define IRAMSIZE 0x13800

#elif CONFIG_CPU == PP5022 || CONFIG_CPU == PP5024
/* PP5022/24 have 128KB of IRAM */
#define DRAMORIG 0x00000000
#define IRAMORIG 0x4000c000
#define IRAMSIZE 0x14000

#elif defined(CPU_PP)
/* all other PP's have 96KB of IRAM */
#define DRAMORIG 0x00000000
#define IRAMORIG 0x4000c000
#define IRAMSIZE 0x0c000

#elif CONFIG_CPU == PNX0101
#define DRAMORIG 0xc00000 + STUBOFFSET
#define IRAMORIG 0x407000
#define IRAMSIZE 0x9000

#elif CONFIG_CPU == IMX31L || CONFIG_CPU == S3C2440
#define DRAMORIG 0x0 + STUBOFFSET
#define IRAM DRAM
#define IRAMSIZE 0

#elif CONFIG_CPU==DM320
#define DRAMORIG CONFIG_SDRAM_START + STUBOFFSET
#define IRAM DRAM
/* The bit of IRAM that is available is used in the core */
#define IRAMSIZE 0

#elif defined(CPU_TCC780X)
#define DRAMORIG 0x20000000
#if CONFIG_CPU==TCC7801
#define IRAMORIG 0x1000c000
#define IRAMSIZE 0xc000
#else
#define IRAM DRAM
#define IRAMSIZE 0
#endif

#elif CONFIG_CPU==AS3525 || CONFIG_CPU==AS3525v2
#if defined(AMS_LOWMEM) || (CONFIG_CPU == AS3525v2)
#define IRAMSIZE 0  /* simulates no IRAM since codec is already entirely in IRAM */
#define CODEC_ORIGIN (IRAM_ORIG + IRAM_SIZE - CODEC_SIZE)
#define PLUGIN_ORIGIN (DRAM_ORIG + DRAMSIZE)
#else
#define IRAMORIG (IRAM_ORIG + 0x20000)
#define IRAMSIZE (IRAM_ORIG + IRAM_SIZE - IRAMORIG)
#endif

#elif CONFIG_CPU==S5L8700
/* S5L8700 have 256KB of IRAM */
#define DRAMORIG 0x08000000
#define IRAMORIG (0x00000000 + (48*1024))
#define IRAMSIZE (208*1024)

#elif CONFIG_CPU==S5L8701
/* S5L8701 have 176KB of IRAM */
#define DRAMORIG 0x08000000
#define IRAMORIG (0x00000000 + (48*1024))
#define IRAMSIZE (128*1024)

#elif CONFIG_CPU==S5L8702
/* S5L8702 have 256KB of IRAM */
/* IRAM1 (2nd 128KB block) is not used because it is slower than DRAM */
#define DRAMORIG 0x08000000
#define IRAMORIG (0x00000000 + (48*1024))
#define IRAMSIZE (80*1024)

#elif CONFIG_CPU == JZ4732 || CONFIG_CPU == JZ4760B
#undef STUBOFFSET
#ifdef DEBUG
#define STUBOFFSET 0x14000
#else
#define STUBOFFSET 0x4000
#endif
#define DRAMORIG 0x80000000 + STUBOFFSET
#define IRAM DRAM
#define IRAMSIZE 0
/* The bit of IRAM that is available is used in the core */

#elif CONFIG_CPU == X1000
#define DRAMORIG X1000_DRAM_BASE
#define IRAM DRAM
#define IRAMSIZE 0

#elif CONFIG_CPU == RK27XX
#define DRAMORIG 0x60000000
#define IRAM DRAM
#define IRAMSIZE 0

#elif CONFIG_CPU == IMX233
#include "cpu.h"
/* The IRAM is too small and already partly used by the core */
#define DRAMORIG CACHED_DRAM_ADDR
#define IRAM DRAM
#define IRAMSIZE 0

#else
#define DRAMORIG 0x09000000 + STUBOFFSET
#endif

#ifndef NOCACHE_BASE
/* Default to no offset if target doesn't define this */
#define NOCACHE_BASE 0x00000000
#endif

#define PLUGIN_LENGTH PLUGIN_BUFFER_SIZE


#ifndef CODEC_ORIGIN /* targets can specify another origin */
#define CODEC_ORIGIN (DRAMORIG + (DRAMSIZE))
#endif

#ifndef PLUGIN_ORIGIN /* targets can specify another origin */
#define PLUGIN_ORIGIN (CODEC_ORIGIN + CODEC_SIZE)
#endif

#ifdef CODEC
#define THIS_LENGTH CODEC_SIZE
#define THIS_ORIGIN CODEC_ORIGIN
#elif defined OVERLAY_OFFSET
#define THIS_LENGTH (DRAMSIZE - OVERLAY_OFFSET)
#define THIS_ORIGIN (DRAMORIG + OVERLAY_OFFSET)
#elif defined IMGVDECODER_OFFSET
#define THIS_LENGTH (PLUGIN_LENGTH - IMGVDECODER_OFFSET)
#define THIS_ORIGIN (PLUGIN_ORIGIN + IMGVDECODER_OFFSET)
#else /* plugin */
#define THIS_LENGTH PLUGIN_LENGTH
#define THIS_ORIGIN PLUGIN_ORIGIN
#endif

MEMORY
{
   PLUGIN_RAM : ORIGIN = THIS_ORIGIN, LENGTH = THIS_LENGTH
#if defined(IRAMSIZE) && IRAMSIZE != 0
   PLUGIN_IRAM : ORIGIN = IRAMORIG, LENGTH = IRAMSIZE
#endif
}

SECTIONS
{
    .header : {
        _plugin_start_addr = .;
        plugin_start_addr = .;
        KEEP(*(.header))
    } > PLUGIN_RAM

    .text :
    {
        *(.text*)
#if defined(IRAMSIZE) && IRAMSIZE == 0
		*(.icode)
#endif
#ifdef CPU_ARM
        *(.glue_7)
        *(.glue_7t)
#endif
    } > PLUGIN_RAM

    .rodata :
    {
        *(SORT_BY_ALIGNMENT(SORT_BY_NAME(.rodata*)))
#if defined(IRAMSIZE) && IRAMSIZE == 0
        *(SORT_BY_ALIGNMENT(SORT_BY_NAME(.irodata)))
#endif
    } > PLUGIN_RAM
#ifdef GCC720
    .got.plt        : { *(.got.plt) }
#endif
    .data :
    {
        *(SORT_BY_ALIGNMENT(SORT_BY_NAME(.data*)))
#if defined(IRAMSIZE) && IRAMSIZE == 0
        *(SORT_BY_ALIGNMENT(SORT_BY_NAME(.idata)))
#endif
    } > PLUGIN_RAM

#ifdef GCC720
    . = .;
    . = .;
    HIDDEN (_gp = ALIGN (16) + 0x7ff0);
    .got :
    {
        *(.got)
    } > PLUGIN_RAM
  /* We want the small data sections together, so single-instruction offsets
     can access them all, and initialized data all before uninitialized, so
     we can shorten the on-disk segment size.  */
    .sdata          :
    {
        *(.sdata .sdata.* .gnu.linkonce.s.*)
    } > PLUGIN_RAM
    .lit8           : { *(.lit8) }
    .lit4           : { *(.lit4) }
    _edata = .; PROVIDE (edata = .);
    . = .;
    __bss_start = .;
    _fbss = .;
    .sbss           :
    {
       *(.dynsbss)
       *(.sbss .sbss.* .gnu.linkonce.sb.*)
       *(.scommon)
    } > PLUGIN_RAM
#endif

#if NOCACHE_BASE != 0
    .ncdata . + NOCACHE_BASE :
    {
        . = ALIGN(CACHEALIGN_SIZE);
        *(.ncdata*)
        . = ALIGN(CACHEALIGN_SIZE);
/* EABI currently needs these defined here, otherwise .iram and .bss can
   sometimes have an incorrect load address, breaking codecs and plugins. */
        bssaddr = . - NOCACHE_BASE;
#if defined(IRAMSIZE) && IRAMSIZE != 0
        iramcopy = . - NOCACHE_BASE;
#endif
    } AT> PLUGIN_RAM
/* This definition is used when NOCACHE_BASE is 0. The address offset bug only
   seems to occur when the empty .ncdata is present. */
#else
    bssaddr = .;
#if defined(IRAMSIZE) && IRAMSIZE != 0
    iramcopy = .;
#endif
#endif

    /DISCARD/ :
    {
        *(.eh_frame)
#ifdef CPU_MIPS
        *(.MIPS.abiflags)
        *(.rel.dyn)
#endif
    }

    .bss bssaddr (NOLOAD) :
    {
    	plugin_bss_start = .;
    	_plugin_bss_start = .;
        *(.bss*)
#if defined(IRAMSIZE) && IRAMSIZE == 0
        *(.ibss)
#endif
        *(COMMON)
#ifdef GCC720
   /* Align here to ensure that the .bss section occupies space up to
      _end.  Align after .bss to ensure correct alignment even if the
      .bss section disappears because there are no input sections.
      FIXME: Why do we need it? When there is no .bss section, we don't
      pad the .data section.  */
   . = ALIGN(. != 0 ? 32 / 8 : 1);
#else
        . = ALIGN(0x4);
#endif
    } > PLUGIN_RAM
#ifdef GCC720
      . = ALIGN(32 / 8);
#endif

#if NOCACHE_BASE != 0
    .ncbss . + NOCACHE_BASE (NOLOAD) :
    {
    	. = ALIGN(CACHEALIGN_SIZE);
    	*(.ncbss*)
        . = ALIGN(CACHEALIGN_SIZE);
        /* We won't trust this one any more than with .ncdata */
        pluginendaddr = . - NOCACHE_BASE;
    } AT> PLUGIN_RAM
#else
    pluginendaddr = .;
#endif

    /* Final end of plugin after IRAM setup. The plugin or codec buffer
       is considered unused by the in-RAM image at this point once IRAM
       is copied. */
    .pluginend pluginendaddr :
    {
        _plugin_end_addr = .;
        plugin_end_addr = .;
    }

#if defined(IRAMSIZE) && IRAMSIZE != 0
    .iram IRAMORIG : AT (iramcopy)
    {
        iramstart = .;
        *(.icode)
        *(.irodata)
        *(.idata)
        iramend = .;
    } > PLUGIN_IRAM

    .ibss (NOLOAD) :
    {
        iedata = .;
        *(.ibss)
        . = ALIGN(0x4);
        iend = .;
    } > PLUGIN_IRAM

    loadendaddr = MAX(plugin_end_addr, LOADADDR(.iram) + SIZEOF(.iram));
#else
    loadendaddr = plugin_end_addr;
#endif

    /* This is for ovl_offset.pl and is the highest address that must
       be loaded into the plugin buffer (past the end of last data in
       stored image). */
    .pluginloadend loadendaddr :
    {
    	_plugin_load_end_addr = .;
    	plugin_load_end_addr = .;
    }

    /* Special trick to avoid a linker error when no other sections are
       left after garbage collection (plugin not for this platform) */
    .comment 0 :
    {
        KEEP(*(.comment))
    }
}
