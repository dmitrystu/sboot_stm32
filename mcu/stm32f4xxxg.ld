ENTRY(Reset_Handler)
MEMORY
{
    ROM    (rx): ORIGIN = 0x08000000, LENGTH = 1024K
    BANK0  (rx): ORIGIN = 0x08000000, LENGTH = 512K
    BANK1  (rx): ORIGIN = 0x08080000, LENGTH = 512K
    RAM   (rwx): ORIGIN = 0x20000000, LENGTH = 192K
    SRAM1 (rwx): ORIGIN = 0x20000000, LENGTH = 112K
    SRAM2 (rwx): ORIGIN = 0x2001C000, LENGTH = 16K
    SRAM3 (rwx): ORIGIN = 0x20020000, LENGTH = 64K
    CMRAM (rwx): ORIGIN = 0x10000000, LENGTH = 64K
}
SECTIONS
{
    .text :
    {
        KEEP(*(.isr_vector))
        *(.text*)
        *(.rodata*)
    } > ROM

    . = ALIGN(4);
    __etext = .;
    . = . + SIZEOF(.data);
    /* 16 kb sector alignment */
    __app_start = ALIGN(0x4000);

    .data : AT (__etext)
    {
        . = ALIGN(4);
        __data_start__ = .;
        *(.data*)
        . = ALIGN(4);
        __data_end__ = .;
    } > RAM

    .bss (NOLOAD):
    {
        . = ALIGN(4);
        __bss_start__ = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end__ = .;
    } > RAM
    PROVIDE(__romend = ORIGIN(ROM) + LENGTH(ROM));
    PROVIDE(__stack = ORIGIN(RAM) + LENGTH(RAM) - 4);
}
