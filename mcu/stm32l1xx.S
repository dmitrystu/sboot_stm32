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

#else
    #error "Bootstrap port undefined"
#endif


    .syntax unified
    .cpu cortex-m3
    .fpu softvfp
    .thumb

    .section .isr_vector
    .align 2
    .globl __isr_vector
__isr_vector:
    .long   __stack                     /* 0x000 Reset MSP value */
    .long   Reset_Handler               /* 0x004 Reset */
    .long   NMI_Handler                 /* 0x008 NMI */

    .word   HardFault_Handler           /* 0x00C All class of fault */
    .word   MemManage_Handler           /* 0x010 Memory management */
    .word   BusFault_Handler            /* 0x014 Pre-fetch fault, memory access fault */
    .word   UsageFault_Handler          /* 0x018 Undefined instruction or illegal state */
    .word   0                           /* 0x01C Reserved */
    .word   0                           /* 0x020 Reserved */
    .word   0                           /* 0x024 Reserved */
    .word   0                           /* 0x028 Reserved */
    .word   SVC_Handler                 /* 0x02C System service call via SWI instruction */
    .word   DebugMon_Handler            /* 0x030 Debug monitor */
    .word   0                           /* 0x034 Reserved */
    .word   PendSV_Handler
    .word   SysTick_Handler
#if !defined(DFU_NO_EXTINT)
/* STM32 Pripherals interrupts */
    .word   WWDG_IRQHandler             /*  0 Window Watchdog interrupt */
    .word   PVD_IRQHandler              /*  1 PVD through EXTI line16 detection interrupt */
    .word   TAMPER_STAMP_IRQHandler     /*  2 Tamper, LSECSS and TimeStamp through EXTI line19 interrupts */
    .word   RTC_WKUP_IRQHandler         /*  3 RTC Wakeup through EXTI line20 interrupt */
    .word   FLASH_IRQHandler            /*  4 Flash global interrupt */
    .word   RCC_IRQHandler              /*  5 RCC global interrupt */
    .word   EXTI0_IRQHandler            /*  6 EXTI Line0 interrupt */
    .word   EXTI1_IRQHandler            /*  7 EXTI Line1 interrupt */
    .word   EXTI2_IRQHandler            /*  8 EXTI Line2 interrupt */
    .word   EXTI3_IRQHandler            /*  9 EXTI Line3 interrupt */
    .word   EXTI4_IRQHandler            /* 10 EXTI Line4 interrupt */
    .word   DMA1_Channel1_IRQHandler    /* 11 DMA1 Channel1 global interrupt */
    .word   DMA1_Channel2_IRQHandler    /* 12 DMA1 Channel2 global interrupt */
    .word   DMA1_Channel3_IRQHandler    /* 13 DMA1 Channel3 global interrupt */
    .word   DMA1_Channel4_IRQHandler    /* 14 DMA1 Channel4 global interrupt */
    .word   DMA1_Channel5_IRQHandler    /* 15 DMA1 Channel5 global interrupt */
    .word   DMA1_Channel6_IRQHandler    /* 16 DMA1 Channel6 global interrupt */
    .word   DMA1_Channel7_IRQHandler    /* 17 DMA1 Channel7 global interrupt */
    .word   ADC1_IRQHandler
    .word   USB_HP_IRQHandler
    .word   USB_LP_IRQHandler
    .word   DAC_IRQHandler
    .word   COMP_IRQHandler
    .word   EXTI9_5_IRQHandler
    .word   LCD_IRQHandler
    .word   TIM9_IRQHandler
    .word   TIM10_IRQHandler
    .word   TIM11_IRQHandler
    .word   TIM2_IRQHandler
    .word   TIM3_IRQHandler
    .word   TIM4_IRQHandler
    .word   I2C1_EV_IRQHandler
    .word   I2C1_ER_IRQHandler
    .word   I2C2_EV_IRQHandler
    .word   I2C2_ER_IRQHandler
    .word   SPI1_IRQHandler
    .word   SPI2_IRQHandler
    .word   USART1_IRQHandler
    .word   USART2_IRQHandler
    .word   USART3_IRQHandler               /* 0x0DC */
    .word   EXTI15_10_IRQHandler            /* 0x0E0 */
    .word   RTC_Alarm_IRQHandler            /* 0x0E4 */
    .word   USB_FS_WKUP_IRQHandler          /* 0x0E8 */
    .word   TIM6_IRQHandler                 /* 0x0EC */
    .word   TIM7_IRQHandler                 /* 0x0F0 */
    .word   0                               /* 0x0F4 */
    .word   TIM5_IRQHandler                 /* 0x0F8 */
    .word   SPI3_IRQHandler                 /* 0x0FC */
    .word   0                               /* 0x100 */
    .word   0                               /* 0x104 */
    .word   DMA2_Channel1_IRQHandler        /* 0x108 */
    .word   DMA2_Channel2_IRQHandler        /* 0x10C */
    .word   DMA2_Channel3_IRQHandler        /* 0x110 */
    .word   DMA2_Channel4_IRQHandler        /* 0x114 */
    .word   DMA2_Channel5_IRQHandler        /* 0x118 */
    .word   AES_IRQHandler                  /* 0x11C */
    .word   COMP_ACQ_IRQHandler             /* 0x120 */

#endif
    .size __isr_vector, . - __isr_vector



    .section .text
    .thumb_func
    .globl Reset_Handler
    .type Reset_Handler, %function
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
    strb    r2, [r0, #RCC_AHBENR]
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
    strb    r2, [r0, #RCC_AHBRSTR]
    movs    r2, #0x00
    strb    r2, [r0, #RCC_AHBRSTR]
    strb    r2, [r0, #RCC_AHBENR]
    cbz     r4, .L_start_boot

/* jump to user section */
    ldr     r0, =__app_start
    ldr     r1, =#SCB
    str     r0, [r1, #SCB_VTOR] //set VTOR
    ldr     r1, [r0, #0x00]     //load new MSP
    msr     MSP, r1             //set MSP
    ldr     r3, [r0, #0x04]     //load reet vector
    bx      r3                  //jump to user_app

/* jump to main app */
.L_start_boot:
/* do copy data */
    ldr     r1, =__etext
    ldr     r2, =__data_start__
    ldr     r3, =__data_end__
.L_copy_data:
    cmp     r2, r3
    bcs     .L_clear_bss
    ldr     r0, [r1], #0x04
    str     r0, [r2], #0x04
    b       .L_copy_data
.L_clear_bss:
    movs    r0, #0x00
    ldr     r2, =__bss_start__
    ldr     r3, =__bss_end__
.L_clear_bss_loop:
    str     r0, [r2], #0x04
    cmp     r3, r2
    bcs     .L_clear_bss_loop

/* Setup clock 24Mhz HSI PLL for USB use
 * All registers means their reset values
 */

/* Enabling PWR interface */
    ldr     r3, =#RCC_BASE
    movs    r1, #0x01
    lsls    r1, 28
    str     r1, [r3, #RCC_APB1ENR]
/* Set Power range 2 */
    ldr     r0, =#PWR_BASE
    lsrs    r1, #16
    str     r1, [r0, #PWR_CR]
.L_wait_pw_set:
    ldr     r1, [r0, #PWR_CSR]
    lsrs    r1, #5                  //VOSF->CF
    bcs     .L_wait_pw_set
/* Set latency 1 */
    ldr     r0, =#FLASH_R_BASE
    movs    r1, #0x04
    str     r1, [r0, #FLASH_ACR]
    movs    r1, #0x05
    str     r1, [r0, #FLASH_ACR]
/* set PLL 6/4 HSI */
    movs    r1, #0xC8
    strb    r1, [r3, #RCC_CFGR + 2] //use byte access
/* enable HSI16 */
    movs    r1, #0x01
    strb    r1, [r3, #RCC_CR + 0]   //set HSI on
.L_wait_HSI:
    ldrb    r2, [r3, #RCC_CR + 0]
    lsrs    r2, #2                  //HSIRDYF -> CF
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



    b       main
    .size Reset_Handler, .-Reset_Handler


    .thumb_func
    .type _default_handler, %function
_default_handler:
    b   .
    .size _default_handler, . - _default_handler


    .pool

    .macro def_irq_handler handler_name
    .weak \handler_name
    .thumb_set \handler_name, _default_handler
    .endm


    def_irq_handler NMI_Handler
    def_irq_handler HardFault_Handler
    def_irq_handler MemManage_Handler
    def_irq_handler BusFault_Handler
    def_irq_handler UsageFault_Handler
    def_irq_handler SVC_Handler
    def_irq_handler DebugMon_Handler
    def_irq_handler PendSV_Handler
    def_irq_handler SysTick_Handler
    def_irq_handler WWDG_IRQHandler
    def_irq_handler PVD_IRQHandler
    def_irq_handler TAMPER_STAMP_IRQHandler
    def_irq_handler RTC_WKUP_IRQHandler
    def_irq_handler FLASH_IRQHandler
    def_irq_handler RCC_IRQHandler
    def_irq_handler EXTI0_IRQHandler
    def_irq_handler EXTI1_IRQHandler
    def_irq_handler EXTI2_IRQHandler
    def_irq_handler EXTI3_IRQHandler
    def_irq_handler EXTI4_IRQHandler
    def_irq_handler DMA1_Channel1_IRQHandler
    def_irq_handler DMA1_Channel2_IRQHandler
    def_irq_handler DMA1_Channel3_IRQHandler
    def_irq_handler DMA1_Channel4_IRQHandler
    def_irq_handler DMA1_Channel5_IRQHandler
    def_irq_handler DMA1_Channel6_IRQHandler
    def_irq_handler DMA1_Channel7_IRQHandler
    def_irq_handler ADC1_IRQHandler
    def_irq_handler USB_HP_IRQHandler
    def_irq_handler USB_LP_IRQHandler
    def_irq_handler DAC_IRQHandler
    def_irq_handler COMP_IRQHandler
    def_irq_handler EXTI9_5_IRQHandler
    def_irq_handler LCD_IRQHandler
    def_irq_handler TIM9_IRQHandler
    def_irq_handler TIM10_IRQHandler
    def_irq_handler TIM11_IRQHandler
    def_irq_handler TIM2_IRQHandler
    def_irq_handler TIM3_IRQHandler
    def_irq_handler TIM4_IRQHandler
    def_irq_handler I2C1_EV_IRQHandler
    def_irq_handler I2C1_ER_IRQHandler
    def_irq_handler I2C2_EV_IRQHandler
    def_irq_handler I2C2_ER_IRQHandler
    def_irq_handler SPI1_IRQHandler
    def_irq_handler SPI2_IRQHandler
    def_irq_handler USART1_IRQHandler
    def_irq_handler USART2_IRQHandler
    def_irq_handler USART3_IRQHandler
    def_irq_handler EXTI15_10_IRQHandler
    def_irq_handler RTC_Alarm_IRQHandler
    def_irq_handler USB_FS_WKUP_IRQHandler
    def_irq_handler TIM6_IRQHandler
    def_irq_handler TIM7_IRQHandler
    def_irq_handler TIM5_IRQHandler
    def_irq_handler SPI3_IRQHandler
    def_irq_handler DMA2_Channel1_IRQHandler
    def_irq_handler DMA2_Channel2_IRQHandler
    def_irq_handler DMA2_Channel3_IRQHandler
    def_irq_handler DMA2_Channel4_IRQHandler
    def_irq_handler DMA2_Channel5_IRQHandler
    def_irq_handler AES_IRQHandler
    def_irq_handler COMP_ACQ_IRQHandler
