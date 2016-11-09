OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
MEMORY
{
    ROM     (rx) : ORIGIN = 0x08000000, LENGTH = 384K
    RAM    (rwx) : ORIGIN = 0x20000000, LENGTH = 48K
    EEPROM  (rw) : ORIGIN = 0x08080000, LENGTH = 12K
}
SECTIONS
{
    .text :
    {
        KEEP(*(.isr_vector))
        *(.text*)
        *(.rodata*)
        . = ALIGN(4);
        __etext = .;
        . = . + SIZEOF(.data);
        __usrapp = ALIGN (0x1000);
    } > ROM

    .data : AT (__etext)
    {
        . = ALIGN(4);
        __data_start__ = .;
        *(.data*)
        . = ALIGN(4);
        /* All data end */
        __data_end__ = .;
    } > RAM

    .bss (NOLOAD):
    {
        __bss_start__ = .;
        *(.bss*)
        *(COMMON)
        __bss_end__ = .;
    } > RAM
    PROVIDE(__romend = ORIGIN(ROM) + LENGTH(ROM));
    PROVIDE(__stack = ORIGIN(RAM) + LENGTH(RAM) - 4);
    PROVIDE(__app_start = __usrapp);
	PROVIDE(__ee_start = ORIGIN(EEPROM));
	PROVIDE(__ee_end = ORIGIN(EEPROM) + LENGTH(EEPROM));
}