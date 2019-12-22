#include "config.h"
#define FLASH_R_BASE    0x40022000
#define FLASH_ACR       0x00
#define FLASH_KEYR      0x04
#define FLASH_OPTKEYR   0x08
#define FLASH_SR        0x0C
#define FLASH_CR        0x10
#define FLASH_AR        0x14
#define FLASH_OBR       0x1C

#define FLASH_OB_BASE   0x1FFFF800

#define FLASH_KEY0      0x45670123
#define FLASH_KEY1      0xCDEF89AB


#define RCC_BASE        0x40021000
#define RCC_CR          0x00
#define RCC_CFGR        0x04
#define RCC_APB1ENR     0x1C
#define RCC_AHBENR      0x14
#define RCC_AHBRSTR     0x28
#define RCC_CFGR3       0x30

#define GPIOA           0x48000000
#define GPIOB           0x48000400
#define GPIOC           0x48000800
#define GPIOD           0x48000C00
#define GPIOF           0x48001400

#define GPIO_MODER      0x00
#define GPIO_OTYPER     0x04
#define GPIO_PUPDR      0x0C
#define GPIO_IDR        0x10

#define SCB             0xE000ED00
#define SCB_VTOR        0x08

#if (DFU_APP_START == _AUTO)
    #define _APP_START  __app_start
#else
    #define _APP_START  DFU_APP_START
#endif

#if (DFU_BOOTKEY_ADDR == _AUTO) || (DFU_BOOTKEY_ADDR == _DISABLE)
    #define _KEY_ADDR   __stack
#else
    #define _KEY_ADDR   DFU_BOOTKEY_ADDR
#endif

#if (DFU_BOOTSTRAP_GPIO == _DISABLE)
    #define BOOTSTRAP_RCC   0x00
#elif (DFU_BOOTSTRAP_GPIO == GPIOA)
    #define BOOTSTRAP_RCC   0x02
#elif (DFU_BOOTSTRAP_GPIO == GPIOB)
    #define BOOTSTRAP_RCC   0x04
#elif (DFU_BOOTSTRAP_GPIO == GPIOC)
    #define BOOTSTRAP_RCC   0x08
#elif (DFU_BOOTSTRAP_GPIO == GPIOD)
    #define BOOTSTRAP_RCC   0x10
#elif (DFU_BOOTSTRAP_GPIO == GPIOF)
    #define BOOTSTRAP_RCC   0x40
#else
    #error Incorrect DFU_BOOTSTRAP_GPIO. Check Config!!
#endif

#if ((DFU_BOOTSTRAP_PIN < 0) || (DFU_BOOTSTRAP_PIN > 15)) && (DFU_BOOTSTRAP_GPIO != _DISABLE)
    #error Incorrect DFU_BOOTSTRAP_PIN. Check config !!
#endif

#if defined(STM32F030x4) || defined(STM32F030x6) || \
    defined(STM32F030x8) || defined(STM32F070x8)
    #define FLASH_PAGESZ 0x400
#else
    #define FLASH_PAGESZ 0x800
#endif

    .syntax unified
    .cpu cortex-m0
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
/* Peripheral interrupts are not used */
    .size    __isr_vector, . - __isr_vector

    .section .text
    .thumb
    .thumb_func
    .align 2
    .globl   Reset_Handler
    .type    Reset_Handler, %function
Reset_Handler:
#if (DFU_BOOTKEY_ADDR != _DISABLE) || (DFU_DBLRESET_MS != _DISABLE)
    ldr     r1, =#_KEY_ADDR
    ldr     r2, =#DFU_BOOTKEY
    movs    r3, #0x00
    ldr     r0, [r1, #0x00]
    str     r3, [r1, #0x00]
    cmp     r0, r2
    beq     .L_start_boot
#endif

#if (DFU_DBLRESET_MS != _DISABLE)
/* Storing DFU_BOOTKEY at DFU_BOOTKEY_ADDR and do a delay.
 * In case of RESET at this time bootloader will start from code above. */
    str     r2, [r1]
/* STM32L0 startup clock is about 8MHz HSI
 * so, we need T(mS)*8000 ticks to make a required delay */
    ldr     r0, =#(DFU_DBLRESET_MS * 8000 / 3)
.L_rst_delay:
    subs    r0, #1              //+1 tick
    bhs     .L_rst_delay        //+2 ticks, 3 ticks/cycle
/* Clearing bootkey and continue */
    str     r3, [r1]
#endif

#if (DFU_BOOTSTRAP_GPIO != _DISABLE)
/* checking bootstrap pin */
    ldr     r0, =#RCC_BASE
    ldr     r1, =#DFU_BOOTSTRAP_GPIO
    movs    r2, #BOOTSTRAP_RCC
    strb    r2, [r0, #RCC_AHBENR + 0x02]

    movs    r2, #0x03
    lsls    r2, #(DFU_BOOTSTRAP_PIN * 2)
    ldr     r3, [r1, #GPIO_MODER]
    bics    r3, r2
    str     r3, [r1, #GPIO_MODER]
    ldr     r3, [r1, #GPIO_PUPDR]
    bics    r3, r2
#if (DFU_BOOTSTRAP_PULL == _DISABLE)
    movs    r2, #0x00
#elif ((DFU_BOOTSTRAP_PULL == _LOW) || ((DFU_BOOTSTRAP_PULL == _AUTO) && (DFU_BOOTSTRAP_LEVEL == _HIGH)))
    movs    r2, #0x02       //pulldown
#else
    movs    r2, #0x01       //pullup
#endif
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
#if (DFU_BOOTSTRAP_LEVEL == _HIGH)
    subs    r4, r2
#else
    adds    r4, r2
#endif
    beq     .L_reset_gpio
    cmp     r4, #0x10
    bne     .L_scan_bootstrap
.L_reset_gpio:
    movs    r2, #BOOTSTRAP_RCC
    strh    r2, [r0, #RCC_AHBRSTR + 0x02]
    movs    r2, #0x00
    strh    r2, [r0, #RCC_AHBRSTR + 0x02]
    strh    r2, [r0, #RCC_AHBENR + 0x02]
    tst     r4, r4
    beq     .L_start_boot
#endif

#if (DFU_VERIFY_CHECKSUM != _DISABLE)
    ldr     r0, =#_APP_START
    ldr     r1, =#__romend
    subs    r1, r0
    bl      validate_checksum
    tst     r0, r0
    beq     .L_start_boot
#endif

/* jump to user section */
    ldr     r0, =#_APP_START
    ldr     r1, =#SCB
    str     r0, [r1, #SCB_VTOR] //set VTOR
    ldr     r1, [r0, #0x00]
    msr     MSP, r1             //set MSP
    ldr     r3, [r0, #0x04]     //load reset vector
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

/* Setup clock 48Mhz HSI PLL for USB use
 * All registers means their reset values
 */
/* Set latency 1 */
    ldr     r0, =#FLASH_R_BASE
    movs    r1, #0x01
    str     r1, [r0, #FLASH_ACR]
    ldr     r3, =#RCC_BASE
/* set PLL 12 * HSI/2 */
    movs    r1, #0x68               // PLLMUL12 | USB_PRE
    strb    r1, [r3, #RCC_CFGR + 2] //use byte access
/* enable PLL */
    movs    r1, #0x01
    strb    r1, [r3, #RCC_CR + 3]   //PLL ON
.L_wait_PLL:
    ldrb    r2, [r3, #RCC_CR + 3]
    lsrs    r2, #2                  //PLLRDYF -> CF
    bcc     .L_wait_PLL
/* set SW[1:0] to PLL */
    movs    r1, #0x02
    strb    r1, [r3, #RCC_CFGR + 0]
/* Enable USB clock */
    movs    r1, #0x80
    strh    r1, [r3, #RCC_CFGR3]

#if (DFU_SEAL_LEVEL != 0)
    ldr     r3, =#seal_flash
    blx     r3
#endif
/* jump to bootloader */
    bl       main

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


    .section .data.program_flash
    .align 2
    .thumb_func
    .globl program_flash
    .type program_flash, %function
/* R0 <- addrss to flash
 * R1 <- buffer
 * R2 <- block size (nonzero less than 0x40)
 * R0 -> DFU_STATUS
 */
program_flash:
    push    {r4, r5, lr}
/* checking halfword alignment */
    lsrs    r4, r0, #0x01
    bcs     Err_unaligned
/* unlocking flash */
    ldr     r3, =#FLASH_R_BASE
    ldr     r4, =#FLASH_KEY0
    ldr     r5, =#FLASH_KEY1
    str     r4, [r3, #FLASH_KEYR]
    str     r5, [r3, #FLASH_KEYR]
/* main flash loop */
.L_flash_loop:
    subs    r2, #0x02
    blt     Err_done
/* check for the page start (1k/2k page)*/
#if (FLASH_PAGESZ == 0x200)
    lsls    r4, r0, #22
#else
    lsls    r4, r0, #21
#endif
    bne     .L_do_write
/* erasing page */
    movs    r4, #0x02               // PER
    str     r4, [r3, #FLASH_CR]
    str     r0, [r3, #FLASH_AR]
    movs    r4, #0x42               // PER + START
    str     r4, [r3, #FLASH_CR]
    bl      wait_prog_done
    bcc     Err_erase
.L_do_write:
    movs    r4, #0x01               // PG
    str     r4, [r3, #FLASH_CR]
    ldrh    r5, [r1]
    strh    r5, [r0]
    bl      wait_prog_done
    bcc     Err_prog
    ldrh    r4, [r0]
    cmp     r5, r4
    bne     Err_verify
    adds    r0, #0x02
    adds    r1, #0x02
    b       .L_flash_loop
Err_done:
    movs    r0, #0x00       //OK
    b       .L_exit
Err_unaligned:
    movs    r0, #0x03       //errWRITE (unaligned access)
    b       .L_exit
Err_erase:
    movs    r0, #0x04       //errERASE
    b       .L_exit
Err_prog:
    movs    r0, #0x06       //errPROG
    b       .L_exit
Err_verify:
    movs    r0, #0x07       //errVERIFY
.L_exit:
/* clear FLASH_SR */
    movs    r4, #0x64
    str     r4, [r3, #FLASH_SR]
/* locking flash */
    movs    r4, 0x80
    str     r4, [r3, #FLASH_CR]
    pop     {r4, r5, pc}
    .size program_flash, . - program_flash


    .thumb_func
    .section .data.wait_prog_done
    .type wait_prog_done, %function
wait_prog_done:
    ldr     r4, [r3, #FLASH_SR]
    lsrs    r4, #0x01               //BSY -> CF
    bcs     wait_prog_done          //wait BSY low
    lsrs    r4, #0x05               //EOP -> CF
    ldr     r4, [r3, #FLASH_SR]
    str     r4, [r3, #FLASH_SR]     // clean FLASH_SR
    bx      lr
    .size wait_prog_done, . - wait_prog_done


#if (DFU_SEAL_LEVEL != 0)
    .thumb_func
    .section .data.seal_flash
    .type seal_flash, %function
/* R0 -> DFU_STATUS */
seal_flash:
    ldr     r3, =#FLASH_R_BASE
    ldr     r0, [r3, #FLASH_OBR]
    movs    r1, #0x03
    ands    r1, r0
    beq     .L_seal
    bx      lr
.L_seal:
/* unlocking flash */
    ldr     r1, =#FLASH_KEY0
    ldr     r2, =#FLASH_KEY1
    str     r1, [r3, #FLASH_KEYR]
    str     r2, [r3, #FLASH_KEYR]
/* unlocking OPTION programming */
    str     r1, [r3, #FLASH_OPTKEYR]
    str     r2, [r3, #FLASH_OPTKEYR]
/* erasing OPTION data. */
    ldr     r0, [r3, #FLASH_CR]
    movs    r1, #0x20               // OPTER
    orrs    r1, r0
    str     r1, [r3, #FLASH_CR]
    movs    r1, #0x60               // START + OPTER
    orrs    r1, r0
    str     r1, [r3, #FLASH_CR]
    bl      wait_prog_done
/* set RDP */
    str     r0, [r3, #FLASH_CR]     // restoring CR
    movs    r1, #0x10               // OPTPG
    orrs    r1, r0
    str     r1, [r3, #FLASH_CR]
    ldr     r0, =#FLASH_OB_BASE
#if (DFU_SEAL_LEVEL == 2)
    ldr     r1, =#0x33CC
#else
    ldr     r1, =#0x44BB
#endif
    strh    r1, [r0, #0x00]
    bl      wait_prog_done
/* reset */
    ldr     r1,=#0x2000             //OBL_LAUNCH
    str     r1, [r3, #FLASH_CR]
    b       .                       //loop forever till reset
    .size seal_flash, . - seal_flash
#endif
    .pool

    .end