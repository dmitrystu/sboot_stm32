#include "config.h"
#define FLASH_R_BASE    0x40022000
#define FLASH_ACR       0x00
#define FLASH_KEYR      0x04
#define FLASH_OPTKEYR   0x08
#define FLASH_SR        0x0C
#define FLASH_CR        0x10
#define FLASH_AR        0x14
#define FLASH_OBR       0x1C
#define FLASH_WRPR      0x20
#define FLASH_OP_BASE   0x1FFFF800


#define FLASH_KEY0      0x45670123
#define FLASH_KEY1      0xCDEF89AB
#define FLASH_PAGESZ    0x800

#define RCC_BASE        0x40021000
#define RCC_CR          0x00
#define RCC_CFGR        0x04
#define RCC_APB2RSTR    0x0C
#define RCC_APB2ENR     0x18
#define RCC_CFGR2       0x2C

#define GPIOA           0x40010800
#define GPIOB           0x40010C00
#define GPIOC           0x40011000
#define GPIOD           0x40011400
#define GPIOE           0x40011800
#define GPIOF           0x40011C00
#define GPIOG           0x40012000

#define GPIO_CRL        0x00
#define GPIO_CRH        0x04
#define GPIO_IDR        0x08
#define GPIO_BSRR       0x10

#define SCB             0xE000ED00
#define SCB_VTOR        0x08
#define SCB_AIRCR       0x0C

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
    #define BOOTSTRAP_RCC   0x04
#elif (DFU_BOOTSTRAP_GPIO == GPIOB)
    #define BOOTSTRAP_RCC   0x08
#elif (DFU_BOOTSTRAP_GPIO == GPIOC)
    #define BOOTSTRAP_RCC   0x10
#elif (DFU_BOOTSTRAP_GPIO == GPIOD)
    #define BOOTSTRAP_RCC   0x20
#elif (DFU_BOOTSTRAP_GPIO == GPIOE)
    #define BOOTSTRAP_RCC   0x40
#elif (DFU_BOOTSTRAP_GPIO == GPIOF)
    #define BOOTSTRAP_RCC   0x80
#else
    #error Incorrect GPIO settings. Check Config!!
#endif

#if (DFU_BOOTSTRAP_PIN >= 0) && (DFU_BOOTSTRAP_PIN <= 7)
    #define BOOTSTRAP_CRx   GPIO_CRL
#elif (DFU_BOOTSTRAP_PIN >= 8) && (DFU_BOOTSTRAP_PIN <= 15)
    #define BOOTSTRAP_CRx   GPIO_CRH
#elif ((DFU_BOOTSTRAP_GPIO != _DISABLE))
    #error Incorrect DFU_BOOTSTRAP_PIN . Check config !!
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
/* Peripheral interrupts are not used */
    .size __isr_vector, . - __isr_vector

    .section .text
    .thumb_func

    .globl  System_Reset
    .type   System_Reset, %function

    .globl Reset_Handler
    .type Reset_Handler, %function
Reset_Handler:
/* Check key */
    ldr     r1, = _KEY_ADDR
    ldr     r2, = DFU_BOOTKEY
    movs    r3, 0x00
    ldr     r4, [r1]
    str     r3, [r1]
    eors    r4, r2  //R4: 0xFFFFFFFF - force APP; 0x00000000 - force BOOT
    mvns    r0, r4
    bne     .L_check_boot
/* jump to user section */
    ldr     r0, = _APP_START
    ldr     r1, = SCB
    str     r0, [r1, SCB_VTOR]  //set VTOR
    ldr     r1, [r0, 0x00]      //load new MSP
    msr     MSP, r1             //set MSP
    ldr     r3, [r0, 0x04]      //load reet vector
    bx      r3                  //jump to user_app
.L_check_boot:
#if (DFU_DBLRESET_MS != _DISABLE)
/* Storing DFU_BOOTKEY at DFU_BOOTKEY_ADDR and do a delay.
 * In case of RESET at this time bootloader will start from code above. */
    str     r2, [r1]
/* STM32F105/7 startup clock is 8.0MHz HSI
 * so, we need T(mS)*8000 ticks to make a required delay */
    ldr     r0, =(DFU_DBLRESET_MS * 8000 / 3)
.L_rst_delay:
    subs    r0, 1              //+1 tick
    bhs     .L_rst_delay        //+2 ticks, 3 ticks/cycle
/* Clearing bootkey and continue */
    str     r3, [r1]
#endif
/* Setup clock 48Mhz HSE PLL for USB */
/* set flash latency 2 */
    ldr     r3, = FLASH_R_BASE
    movs    r0, 0x32
    str     r0, [r3, FLASH_ACR]
/* setup RCC */
    ldr     r5, = RCC_BASE
    movs    r2, 0x1d               // PLLMUL9  | PLLSRC
    strb    r2, [r5, RCC_CFGR + 2]
    movs    r2, 0xc4               // ADCPRE = 8, PPRE2 = 1, PPRE1 = 2
    strb    r2, [r5, RCC_CFGR + 1]
#if defined(HSE_25MHZ)
    movs    r2, 0x01               // PREDIV1SRC = PLL2
    strb    r2, [r5, RCC_CFGR2 + 2]
    movs    r2, 0x66               // PLL3MUL = 8, PLL2MUL = 8
    strb    r2, [r5, RCC_CFGR2 + 1]
    movs    r2, 0x44               // PREDIV2 = 5, PREDIV1 = 5
    strb    r2, [r5, RCC_CFGR2 + 0]
    movs    r2, 0x01               // HSEON = 1
    strb    r2, [r5, RCC_CR + 2]
.L_wait_HSE:
    ldr     r0, [r5, RCC_CR]
    lsrs    r0, 18                 // HSERDY
    bcc     .L_wait_HSE
    movs    r2, 0x04               // PLL2ON = 1
    strb    r2, [r5, RCC_CR + 3]
.L_wait_PLL2:
    ldr     r0, [r5, RCC_CR]
    lsrs    r0, 28                 // PLL2RDY -> CF
    bcc     .L_wait_PLL2
    movs    r2, 0x05               // PLLON = 1, PLL2ON = 1
    strb    r2, [r5, RCC_CR + 3]
#else
    movs    r2, 0x00               // PREDIV1SRC = HSE
    strb    r2, [r5, RCC_CFGR2 + 2]
    movs    r2, 0x66               // PLL3MUL = 8, PLL2MUL = 8
    strb    r2, [r5, RCC_CFGR2 + 1]
    movs    r2, 0x40               // PREDIV2 = 5, PREDIV1 = 1
    strb    r2, [r5, RCC_CFGR2 + 0]
    movs    r2, 0x01               // HSEON = 1
    strb    r2, [r5, RCC_CR + 2]
.L_wait_HSE:
    ldr     r0, [r5, RCC_CR]
    lsrs    r0, 18                 // HSERDY
    bcc     .L_wait_HSE
    movs    r2, 0x01               // PLLON = 1
    strb    r2, [r5, RCC_CR + 3]
#endif
.L_wait_PLL:
    ldr     r0, [r5, RCC_CR]
    lsrs    r0, 26                 // PLLRDY -> CF
    bcc     .L_wait_PLL
/* switch to PLL */
    movs    r2, 0x02               // SW = PLL, HPRE = 1
    strb    r2, [r5, RCC_CFGR + 0 ]
/* Jump to bootloader if bootkey match */
    cbz     r4, .L_start_boot

#if (DFU_BOOTSTRAP_GPIO != _DISABLE)
    movs    r2, BOOTSTRAP_RCC
    strb    r2, [r5, RCC_APB2ENR]
/* checking bootstrap pin */
    ldr     r1, = DFU_BOOTSTRAP_GPIO
    ldr     r3, =(0x0F << ((DFU_BOOTSTRAP_PIN & 0x07) << 2))
#if (DFU_BOOTSTRAP_PULL == _DISABLE)
    ldr     r2, =(0x00 << ((DFU_BOOTSTRAP_PIN & 0x07) << 2))
#else
    ldr     r2, =(0x08 << ((DFU_BOOTSTRAP_PIN & 0x07) << 2))
#endif
    ldr     r0, [r1, BOOTSTRAP_CRx]
    bics    r0, r3
    orrs    r0, r2
    str     r0, [r1, BOOTSTRAP_CRx]
#if ((DFU_BOOTSTRAP_PULL == _LOW) || ((DFU_BOOTSTRAP_PULL == _AUTO) && (DFU_BOOTSTRAP_LEVEL == _HIGH)))
    ldr     r2, =(0x01 << (DFU_BOOTSTRAP_PIN * 2)) //pulldown
#else
    ldr     r2, =(0x01 << DFU_BOOTSTRAP_PIN)   //pullup
#endif
    str     r2, [r1, GPIO_BSRR]
    movs    r4, 0x08
.L_scan_bootstrap:
    ldr     r2, [r1, GPIO_IDR]
    lsrs    r2, (DFU_BOOTSTRAP_PIN + 1)    //Pin -> CF
    sbcs    r3, r3
    movs    r2, 0x01
    orrs    r2, r3
#if (DFU_BOOTSTRAP_LEVEL == _HIGH)
    subs    r4, r2
#else
    adds    r4, r2
#endif
    beq     .L_reset_gpio
    cmp     r4, 0x10
    bne     .L_scan_bootstrap
.L_reset_gpio:
/* resetting gpio back */
    movs    r2, BOOTSTRAP_RCC
    strb    r2, [r5, RCC_APB2RSTR]
    movs    r2, 0x00
    strb    r2, [r5, RCC_APB2RSTR]
    strb    r2, [r5, RCC_APB2ENR]
    cbz     r4, .L_start_boot
#endif

#if (DFU_VERIFY_CHECKSUM != _DISABLE)
    ldr     r0, = _APP_START
    ldr     r1, = __romend
    sub     r1, r0
    bl      validate_checksum
    cbz     r0, .L_start_boot
#endif

    ldr     r1, = _KEY_ADDR
    ldr     r2, = DFU_BOOTKEY
    mvns    r2, r2
    str     r2, [r1]
System_Reset:
    dsb
    ldr     r1, = SCB
    ldr     r2, = 0x05FA0004;
    str     r2, [r1, SCB_AIRCR]
    b .

/* jump to bootloader */
.L_start_boot:
/* do copy data */
    ldr     r1, =__etext
    ldr     r2, =__data_start__
    ldr     r3, =__data_end__
.L_copy_data:
    ldr     r0, [r1], 0x04
    str     r0, [r2], 0x04
    cmp     r3, r2
    bhi     .L_copy_data
.L_clear_bss:
    movs    r0, 0x00
    ldr     r2, =__bss_start__
    ldr     r3, =__bss_end__
.L_clear_bss_loop:
    str     r0, [r2], 0x04
    cmp     r3, r2
    bhi     .L_clear_bss_loop
#if (DFU_SEAL_LEVEL != 0)
    ldr     r3, =seal_flash
    blx     r3
#endif
    bl      main
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

    .section .data
    .align 2
    .thumb_func
    .globl program_flash
    .type program_flash, %function
/* R0 <- address to flash
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
/* check for the page start (2k page)*/
    lsls    r4, r0, #21
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
    mov     r4, #0x01               // PG
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
    .type wait_prog_done, %function
wait_prog_done:
    ldr     r4, [r3, #FLASH_SR]
    lsrs    r4, #0x01               //BSY -> CF
    bcs     wait_prog_done          //wait BSY low
    lsrs    r4, #0x05               //EOP -> CF
    ldr     r4, [r3, #FLASH_SR]
    str     r4, [r3, #FLASH_SR]     // clean FLASH_SR
    bx      lr


#if (DFU_SEAL_LEVEL != 0)
    .thumb_func
    .type seal_flash, %function
/* R0 -> DFU_STATUS */
seal_flash:
    ldr     r3, =#FLASH_R_BASE
    ldr     r0, [r3, #FLASH_OBR]
    lsrs    r0, #2                  //RDPRT -> CF
    bcc     .L_seal
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
    movs    r1, #0x20               // OPTER
    str     r1, [r3, #FLASH_CR]
    movs    r1, #0x60               // START + OPTER
    str     r1, [r3, #FLASH_CR]
    bl      wait_prog_done
/* set RDP */
    movs    r1, #0x10
    str     r1, [r3, #FLASH_CR]
    ldr     r0, =#FLASH_OP_BASE
    ldr     r1, =#0x33CC
    strh    r1, [r0, #0x00]
    bl      wait_prog_done
/* reset */
    ldr     r3, =#SCB
    ldr     r1, =#0x05FA0004
    str     r1, [r3, #SCB_AIRCR]
    b       .                       //loop forever till reset
    .size seal_flash, . - seal_flash
#endif

    .pool


    .end
