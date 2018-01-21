ENTRY(Reset_Handler)
MEMORY
{
    ROM    (rx): ORIGIN = 0x08000000, LENGTH = 512K
    BANK0  (rx): ORIGIN = 0x08000000, LENGTH = 256K
    BANK1  (rx): ORIGIN = 0x08020000, LENGTH = 256K
    RAM   (rwx): ORIGIN = 0x20000000, LENGTH = 96K
    RAM2  (rwx): ORIGIN = 0x10000000, LENGTH = 32K
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
    __app_start = ALIGN(0x0800);

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
