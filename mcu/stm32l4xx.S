#include "../config.h"
#include "memmap.h"


#if (DFU_BOOTSTRAP_GPIO == GPIOA)
    #define BOOTSTRAP_RCC   0x01
#elif (DFU_BOOTSTRAP_GPIO == GPIOB)
    #define BOOTSTRAP_RCC   0x02
#elif (DFU_BOOTSTRAP_GPIO == GPIOC)
    #define BOOTSTRAP_RCC   0x04
#elif (DFU_BOOTSTRAP_GPIO == GPIOD)
    #define BOOTSTRAP_RCC   0x08
#elif (DFU_BOOTSTRAP_GPIO == GPIOE)
    #define BOOTSTRAP_RCC   0x10
#elif (DFU_BOOTSTRAP_GPIO == GPIOH)
    #define BOOTSTRAP_RCC   0x20
#elif (DFU_BOOTSTRAP_GPIO == GPIOF)
    #define BOOTSTRAP_RCC   0x40
#elif (DFU_BOOTSTRAP_GPIO == GPIOG)
    #define BOOTSTRAP_RCC   0x80
#else
    #error "Bootstrap port undefined"
#endif

    .syntax unified
	.cpu cortex-m4
	.thumb

    .section .isr_vector
    .align 2
    .globl __isr_vector
__isr_vector:
	.long	__stack
	.long	Reset_Handler
	.long	NMI_Handler
	.long	HardFault_Handler
	.long	MemManage_Handler
	.long	BusFault_Handler
	.long	UsageFault_Handler
	.long	0
	.long	0
	.long	0
	.long	0
	.long	SVC_Handler
	.long	DebugMon_Handler
	.long	0
	.long	PendSV_Handler
	.long	SysTick_Handler
/* Peripheral interrupts are not used */
    .size    __isr_vector, . - __isr_vector


    .section	.text
	.thumb_func
	.globl  Reset_Handler
	.type	Reset_Handler, %function
Reset_Handler:
    ldr     r1, =#DFU_BOOTKEY_ADDR
    ldr     r2, =#DFU_BOOTKEY
    movs    r3, #0x00
    ldr     r0, [r1]
    str     r3, [r1]
    cmp     r0, r2
    beq     .L_start_boot
/* checking bootstrap pin */
    ldr     r0, =#RCC_BASE
    ldr     r1, =#DFU_BOOTSTRAP_GPIO
    movs    r2, #BOOTSTRAP_RCC
    strb    r2, [r0, #RCC_AHB2ENR]
    movs    r2, #0x03
    lsls    r2, #(DFU_BOOTSTRAP_PIN * 2)
    ldr     r3, [r1, #GPIO_MODER]
    bics    r3, r2
    str     r3, [r1, #GPIO_MODER]
    ldr     r3, [r1, #GPIO_PUPDR]
    bics    r3, r2
    movs    r2, #0x01
    lsls    r2, #(DFU_BOOTSTRAP_PIN * 2)
    orrs    r3, r2
    str     r3, [r1, #GPIO_PUPDR]
    movs    r4, #0x08
.L_scan_bootstrap:
    ldr     r2, [r1, #GPIO_IDR]
    lsrs    r2, #(DFU_BOOTSTRAP_PIN + 1)    //Pin -> CF
    sbcs    r3, r3
    movs    r2, #0x01
    orrs    r2, r3
    adds    r4, r2
    beq     .L_reset_gpio
    cmp     r4, #0x10
    bne     .L_scan_bootstrap
.L_reset_gpio:
    movs    r2, #BOOTSTRAP_RCC
    strb    r2, [r0, #RCC_AHB2RSTR]
    movs    r2, #0x00
    strb    r2, [r0, #RCC_AHB2RSTR]
    strb    r2, [r0, #RCC_AHB2ENR]
    cbz     r4, .L_start_boot
/* jump to user section */
    ldr     r0, =__app_start
    ldr     r1, =#SCB
    str     r0, [r1, #SCB_VTOR] //set VTOR
    ldr     r1, [r0, #0x00]     //load new MSP
    msr     MSP, r1             //set MSP
    ldr     r3, [r0, #0x04]     //load reet vector
    bx      r3                  //jump to user_app
/* starting bootloader */
.L_start_boot:
    ldr     r1, =__etext
    ldr     r2, =__data_start__
    ldr     r3, =__data_end__
    subs    r3, r2
    ble     .L_clear_bss
.L_copy_data:
    subs    r3, #0x04
    ldr     r0, [r1, r3]
    str     r0, [r2, r3]
    bgt     .L_copy_data
.L_clear_bss:
    ldr     r1, = __bss_start__
    ldr     r2, = __bss_end__
    movs    r3, #0
.L_bss_loop:
    str     r3, [r1]
    adds    r1, #0x04
    cmp     r1, r2
    bcc     .L_bss_loop
/* Enabling PWR interface */
	ldr		r3, =#RCC_BASE
	movs	r1, #0x01
	lsls 	r1, #28		/* PWREN */
	str 	r1, [r3, #RCC_APB1ENR1]
	ldr 	r0, =#PWR_BASE
/* Setting power Range 1 */
	lsrs 	r1, #19 	/* Range 1 */
	str     r1, [r0, #PWR_CR1]
.L_wait_pw_set:
	ldr		r1, [r0, #PWR_SR2]
	lsrs	r1, #11		/* VOSF -> CF */
	bcs 	.L_wait_pw_set
/* Adjusting flash latency */
	ldr		r0, =#FLASH_R_BASE
	movs	r1, #2
	str 	r1, [r0, #FLASH_ACR]
/* Set 48Mhz MSI clock */
	movs	r1, #0xB9
	strb    r1, [r3, #RCC_CR]
/* Set MSI clock as USB clock */
	movs	r1, #0x0C
	strb 	r1, [r3, #RCC_CCIPR + 3]
/* Enabling USB pins GPIOA11 GPIO12 AF10*/
	mov 	r1, #0x01
	strb 	r1, [r3, #RCC_AHB2ENR]
	ldr 	r0, =#GPIOA
	ldr 	r1, [r0, #GPIO_MODER]
	movs	r2, #0xAA
	bfi     r1, r2, #22, #4
	str     r1, [r0, #GPIO_MODER]
	lsls    r2, #12
	str     r2, [r0, #GPIO_AFRH]
/* jump to bootloader */
	bl 		main

	.size Reset_Handler, . - Reset_Handler


_default_handler:
    b .
    .size _default_handler, . - _default_handler


    .pool

    .macro    def_irq_handler    handler_name
    .weak    \handler_name
    .thumb_set \handler_name, _default_handler
    .endm

    def_irq_handler    NMI_Handler
    def_irq_handler    HardFault_Handler
    def_irq_handler    MemManage_Handler
    def_irq_handler    BusFault_Handler
    def_irq_handler    UsageFault_Handler
    def_irq_handler    SVC_Handler
    def_irq_handler    DebugMon_Handler
    def_irq_handler    PendSV_Handler
    def_irq_handler    SysTick_Handler

