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
    .cpu cortex-m0plus
    .fpu softvfp
    .thumb


    .section .isr_vector
    .align 2
    .globl __isr_vector
__isr_vector:
    .long    __stack                        // Top of Stack
    .long    Reset_Handler                  // Reset Handler
    .long    NMI_Handler                    // NMI Handler

    .long    HardFault_Handler              // Hard Fault Handler
    .long    0                              // Reserved
    .long    0                              // Reserved
    .long    0                              // Reserved
    .long    0                              // Reserved
    .long    0                              // Reserved
    .long    0                              // Reserved
    .long    0                              // Reserved
    .long    SVC_Handler                    // SVCall Handler
    .long    DebugMon_Handler               // Debug Monitor Handler
    .long    0                              // Reserved
    .long    PendSV_Handler                 // PendSV Handler
    .long    SysTick_Handler                // SysTick Handler
#if !defined(DFU_NO_EXTINT)
                // External Interrupts
    .long    WWDG_IRQHandler                // 0  Window Watchdog
    .long    PVD_IRQHandler                 // 1  PVD through EXTI Line detect
    .long    RTC_IRQHandler                 // 2  RTC through EXTI Line
    .long    FLASH_IRQHandler               // 3  FLASH
    .long    RCC_CRS_IRQHandler             // 4  RCC and CRS
    .long    EXTI0_1_IRQHandler             // 5  EXTI Line 0 and 1
    .long    EXTI2_3_IRQHandler             // 6  EXTI Line 2 and 3
    .long    EXTI4_15_IRQHandler            // 7  EXTI Line 4 to 15
    .long    TSC_IRQHandler                 // 8  TSC
    .long    DMA1_Channel1_IRQHandler       // 9  DMA1 Channel 1
    .long    DMA1_Channel2_3_IRQHandler     // 10 DMA1 Channel 2 and Channel 3
    .long    DMA1_Channel4_5_6_7_IRQHandler // 11 DMA1 Channel 4, Channel 5, Channel 6 and Channel 7
    .long    ADC1_COMP_IRQHandler           // 12 ADC1, COMP1 and COMP2
    .long    LPTIM1_IRQHandler              // 13 LPTIM1
    .long    USART4_5_IRQHandler            // 14 USART4 USART5
    .long    TIM2_IRQHandler                // 15 TIM2
    .long    TIM3_IRQHandler                // 16 TIM3
    .long    TIM6_DAC_IRQHandler            // 17 TIM6 and DAC
    .long    TIM7_IRQHandler                // 18 TIM7
    .long    0                              // 19 Reserved
    .long    TIM21_IRQHandler               // 20 TIM21
    .long    I2C3_IRQHandler                // 21 I2C3
    .long    TIM22_IRQHandler               // 22 TIM22
    .long    I2C1_IRQHandler                // 23 I2C1
    .long    I2C2_IRQHandler                // 24 I2C2
    .long    SPI1_IRQHandler                // 25 SPI1
    .long    SPI2_IRQHandler                // 26 SPI2
    .long    USART1_IRQHandler              // 27 USART1
    .long    USART2_IRQHandler              // 28 USART2
    .long    AES_RNG_LPUART1_IRQHandler     // 29 AES, RNG and LPUART1
    .long    0                              // 30 Reserved
    .long    USB_IRQHandler                 // 31 USB
#endif
    .size    __isr_vector, . - __isr_vector


    .section .text
    .thumb
    .thumb_func
    .align 2
    .globl   Reset_Handler
    .type    Reset_Handler, %function
Reset_Handler:
    ldr     r1, =#DFU_BOOTKEY_ADDR
    ldr     r2, =#DFU_BOOTKEY
    movs    r3, #0x00
    ldr     r0, [r1, #0x00]
    str     r3, [r1, #0x00]
    cmp     r0, r2
    beq     .L_start_boot
/* checking bootstrap pin */
    ldr     r0, =#RCC_BASE
    ldr     r1, =#DFU_BOOTSTRAP_GPIO
    movs    r2, #BOOTSTRAP_RCC
    str     r2, [r0, #RCC_IOPENR]
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
    movs    r4, #0x10
.L_scan_bootstrap:
    ldr     r2, [r1, #GPIO_IDR]
    lsrs    r2, #(DFU_BOOTSTRAP_PIN + 1)    //Pin -> CF
    sbcs    r3, r3
    movs    r2, #0x01
    orrs    r2, r3
    adds    r4, r2
    beq     .L_reset_gpio
    cmp     r4, #0x20
    bne     .L_scan_bootstrap
.L_reset_gpio:
    movs    r2, #BOOTSTRAP_RCC
    str     r2, [r0, #RCC_IOPRSTR]
    movs    r2, #0x00
    str     r2, [r0, #RCC_IOPRSTR]
    str     r2, [r0, #RCC_IOPENR]
    tst     r4, r4
    beq     .L_start_boot
/* jump to user section */
    ldr     r0, =__app_start
    ldr     r1, =#0xE000ED08
    str     r0, [r1, #0x00]     //set VTOR
    ldr     r1, [r0, #0x00]
    msr     MSP, r1             //set MSP
    ldr     r3, [r0, #0x04]     //load reet vector
    bx      r3                  //jump to user_app
/* copy data and clear bss for bootloader */
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

/* Setup clock 24Mhz HSI PLL for USB use
 * All registers means their reset values
 */

/* Enabling PWR interface */
    ldr     r3, =#RCC_BASE
    movs    r1, #0x10
    lsls    r1, 24
    str     r1, [r3, #RCC_APB1ENR]
/* Set Power range 2 */
    ldr     r0, =#PWR_BASE
    movs    r1, #0x01
    lsls    r1, #11
    str     r1, [r0, #PWR_CR]
.L_wait_pw_set:
    ldr     r1, [r0, #PWR_CSR]
    lsrs    r1, #5              //VOSF->CF
    bcs     .L_wait_pw_set
/* Set latency 1 */
    ldr     r0, =#FLASH_R_BASE
    movs    r1, #0x01
    str     r1, [r0, #FLASH_ACR]
/* set PLL 6/4 HSI */
    movs    r1, #0xC8
    strb    r1, [r3, #RCC_CFGR + 2] //use byte access
/* enable HSI16 */
    movs    r1, #0x01
    strb    r1, [r3, #RCC_CR + 0]   //set HSI on
.L_wait_HSI:
    ldrb    r2, [r3, #RCC_CR + 0]
    lsrs    r2, #3                  //HSIRDYF -> CF
    bcc     .L_wait_HSI
/* enable PLL */
    strb    r1, [r3, #RCC_CR + 3]   //PLL ON
.L_wait_PLL:
    ldrb    r2, [r3, #RCC_CR + 3]
    lsrs    r2, #2                  //PLLRDYF -> CF
    bcc     .L_wait_PLL
/* set SW[1:0] to PLL */
    movs    r1, #0x03
    strb    r1, [r3, #RCC_CFGR + 0]

/* jump to bootloader */
    b       main

    .size Reset_Handler, . - Reset_Handler


/*    Macro to define default handlers. Default handler
 *    will be weak symbol and just dead loops. They can be
 *    overwritten by other handlers */
    .align 2
    .thumb_func
    .type _default_handler, %function

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
    def_irq_handler    SVC_Handler
    def_irq_handler    DebugMon_Handler
    def_irq_handler    PendSV_Handler
    def_irq_handler    SysTick_Handler

                // External Interrupts
    def_irq_handler    WWDG_IRQHandler                // 0  Window Watchdog
    def_irq_handler    PVD_IRQHandler                 // 1  PVD through EXTI Line detect
    def_irq_handler    RTC_IRQHandler                 // 2  RTC through EXTI Line
    def_irq_handler    FLASH_IRQHandler               // 3  FLASH
    def_irq_handler    RCC_CRS_IRQHandler             // 4  RCC and CRS
    def_irq_handler    EXTI0_1_IRQHandler             // 5  EXTI Line 0 and 1
    def_irq_handler    EXTI2_3_IRQHandler             // 6  EXTI Line 2 and 3
    def_irq_handler    EXTI4_15_IRQHandler            // 7  EXTI Line 4 to 15
    def_irq_handler    TSC_IRQHandler                 // 8  TSC
    def_irq_handler    DMA1_Channel1_IRQHandler       // 9  DMA1 Channel 1
    def_irq_handler    DMA1_Channel2_3_IRQHandler     // 10 DMA1 Channel 2 and Channel 3
    def_irq_handler    DMA1_Channel4_5_6_7_IRQHandler // 11 DMA1 Channel 4, Channel 5, Channel 6 and Channel 7
    def_irq_handler    ADC1_COMP_IRQHandler           // 12 ADC1, COMP1 and COMP2
    def_irq_handler    LPTIM1_IRQHandler              // 13 LPTIM1
    def_irq_handler    USART4_5_IRQHandler            // 14 USART4 USART5
    def_irq_handler    TIM2_IRQHandler                // 15 TIM2
    def_irq_handler    TIM3_IRQHandler                // 16 TIM3
    def_irq_handler    TIM6_DAC_IRQHandler            // 17 TIM6 and DAC
    def_irq_handler    TIM7_IRQHandler                // 18 TIM7
    def_irq_handler    TIM21_IRQHandler               // 20 TIM21
    def_irq_handler    I2C3_IRQHandler                // 21 I2C3
    def_irq_handler    TIM22_IRQHandler               // 22 TIM22
    def_irq_handler    I2C1_IRQHandler                // 23 I2C1
    def_irq_handler    I2C2_IRQHandler                // 24 I2C2
    def_irq_handler    SPI1_IRQHandler                // 25 SPI1
    def_irq_handler    SPI2_IRQHandler                // 26 SPI2
    def_irq_handler    USART1_IRQHandler              // 27 USART1
    def_irq_handler    USART2_IRQHandler              // 28 USART2
    def_irq_handler    AES_RNG_LPUART1_IRQHandler     // 29 AES, RNG and LPUART1
    def_irq_handler    USB_IRQHandler                 // 31 USB

    .end
