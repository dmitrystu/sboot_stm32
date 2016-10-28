/*------------------------------------------------------------------------------
 *      Linker script for running in internal FLASH on the STM32L052x8
 *----------------------------------------------------------------------------*/

OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
SEARCH_DIR(.)

/* Memory Spaces Definitions */
MEMORY
{
    ROM     (rx) : ORIGIN = 0x08000000, LENGTH = 64K
    RAM    (rwx) : ORIGIN = 0x20000000, LENGTH = 8K
    EEPROM  (rx) : ORIGIN = 0x08080000, LENGTH = 2K
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
        /* app start is a block aligned */
        __app_start = ALIGN (0x1000);
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


	.eeprom :
	{
		__ee_start = .;
		*(.eeprom*)
	} > EEPROM


	.bss (NOLOAD):
	{
		__bss_start__ = .;
		*(.bss*)
		*(COMMON)
		__bss_end__ = .;
	} > RAM

	/* .stack_dummy section doesn't contains any symbols. It is only
	 * used for linker to calculate size of stack sections, and assign
	 * values to stack symbols later */
	.stack_dummy (NOLOAD):
	{
		*(.stack)
	} > RAM

	/* Set stack top to end of RAM, and stack limit move down by
	 * size of stack_dummy section */
	__StackTop = ORIGIN(RAM) + LENGTH(RAM) - 4;
	__StackLimit = __StackTop - SIZEOF(.stack_dummy);
	PROVIDE(__stack = __StackTop);
	PROVIDE(__romend = ORIGIN(ROM) + LENGTH(ROM));
	PROVIDE(__ee_end = ORIGIN(EEPROM) + LENGTH(EEPROM));
}
