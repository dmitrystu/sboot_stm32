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
#define FLASH_PAGESZ    0x200

#define RCC_BASE        0x40021000
#define RCC_CR          0x00
#define RCC_CFGR        0x04
#define RCC_AHBRSTR     0x28
#define RCC_AHBENR      0x14

#define GPIOA           0x48000000
#define GPIOB           0x48000400
#define GPIOC           0x48000800
#define GPIOD           0x48000C00
#define GPIOE           0x48001000
#define GPIOF           0x48001400
#define GPIOG           0x48001800
#define GPIOH           0x48001C00

#define GPIO_MODER      0x00
#define GPIO_OTYPER     0x04
#define GPIO_OSPEEDR    0x08
#define GPIO_PUPDR      0x0C
#define GPIO_IDR        0x10
#define GPIO_ODR        0x14
#define GPIO_BSRR       0x18
#define GPIO_AFRL       0x20
#define GPIO_AFRH       0x24

#define SCB             0xE000ED00
#define SCB_VTOR        0x08
#define SCB_AIRCR       0x0C

#if (DFU_APP_START == _AUTO)
    #define _APP_START  __app_start
#else
    #define _APP_START  DFU_APP_START
#endif

#if (DFU_APP_SIZE == _AUTO)
    #define _APP_END   __romend
#else
    #define _APP_END   _APP_START + DFU_APP_SIZE
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
#elif (DFU_BOOTSTRAP_GPIO == GPIOE)
    #define BOOTSTRAP_RCC   0x20
#elif (DFU_BOOTSTRAP_GPIO == GPIOF)
    #define BOOTSTRAP_RCC   0x40
#elif (DFU_BOOTSTRAP_GPIO == GPIOG)
    #define BOOTSTRAP_RCC   0x80
#elif (DFU_BOOTSTRAP_GPIO == GPIOH)
    #define BOOTSTRAP_RCC   0x01
#else
    #error Incorrect DFU_BOOTSTRAP_GPIO. Check Config!!
#endif

#if ((DFU_BOOTSTRAP_PIN < 0) || (DFU_BOOTSTRAP_PIN > 15)) && (DFU_BOOTSTRAP_GPIO != _DISABLE)
    #error Incorrect DFU_BOOTSTRAP_PIN. Check config !!
#endif


    .syntax unified
    .cpu cortex-m4
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
/* enabling GPIOA and bootstrap pin GPIO */
    ldr     r5, = RCC_BASE
    movs    r2, 0x02
    strb    r2, [r5, RCC_AHBENR + 0x02]
/* pulling low PA12 (USD-DP) to force device re-enumeration*/
    ldr     r1, = GPIOA
    ldr     r2, [r1, GPIO_MODER]
    ldr     r3, = (0x03 << (12 * 2))
    bics    r2, r3
    ldr     r3, = (0x01 << (12 * 2))
    orr     r2, r3
    str     r2, [r1, GPIO_MODER]
    ldr     r2, = (0x1000 << 12)
    str     r2, [r1, GPIO_BSRR]

/* checking DFU SW bootkey */
    ldr     r1, = _KEY_ADDR
    ldr     r2, = DFU_BOOTKEY
    movs    r3, 0x00
    ldr     r4, [r1]
    str     r3, [r1]
    eors    r4, r2  //R4: 0xFFFFFFFF - force APP; 0x00000000 - force BOOT

#if (DFU_DBLRESET_MS != _DISABLE)
/* Storing DFU_BOOTKEY at DFU_BOOTKEY_ADDR and do a delay.
/* STM32F303 startup clock is 8.0MHz HSI
 * In case of RESET at this time bootloader will start from code above. */
    str     r2, [r1]
#endif
/* At least 20 ms delay with pulled low DP+ */
#if (DFU_DBLRESET_MS > 20)
    #define USB_RST_MS DFU_DBLRESET_MS
#else
    #define USB_RST_MS 20
#endif
    ldr     r3, = (USB_RST_MS * 8000 / 3)
.L_rst_delay:
    subs    r3, 1               //+1 tick
    bne     .L_rst_delay        //+2 ticks, 3 ticks/cycle
    str     r3, [r1]
/* Reset GPIOA */
    movs    r2, 0x02
    strb    r2, [r5, RCC_AHBRSTR + 0x02]
    strb    r3, [r5, RCC_AHBRSTR + 0x02]

/* Continue with key */
    mvns    r0, r4
    bne     .L_setup_clk
/* jump to user section */
    ldr     r0, = _APP_START
    ldr     r1, = SCB
    str     r0, [r1, SCB_VTOR]  //set VTOR
    ldr     r1, [r0, 0x00]      //load new MSP
    msr     MSP, r1             //set MSP
    ldr     r3, [r0, 0x04]      //load reet vector
    bx      r3                  //jump to user_app

.L_setup_clk:
/* Setup clock 48Mhz HSI PLL for USB */
/* set flash latency 1 */
    ldr     r3, = FLASH_R_BASE
    movs    r0, 0x31
    str     r0, [r3, FLASH_ACR]
/* setup RCC */
    movs    r2, 0x68               // PLLMIL12  | USB_PRE
    strb    r2, [r5, RCC_CFGR + 2]
    movs    r2, 0x04
    strb    r2, [r5, RCC_CFGR + 1] // PPRE1 DIV/2 (24Mhz APB1)
    movs    r2, 0x01
    strb    r2, [r5, RCC_CR + 3]
.L_wait_PLL:
    ldr     r0, [r5, RCC_CR]
    lsrs    r0, 26                 // PLLRDY -> CF
    bcc     .L_wait_PLL
/* switch to PLL */
    movs    r2, 0x02
    strb    r2, [r5, RCC_CFGR + 0]
    cbz     r4, .L_start_boot

#if (DFU_BOOTSTRAP_GPIO != _DISABLE)
/* checking bootstrap pin */
    movs    r2, BOOTSTRAP_RCC
    strb    r2, [r5, RCC_AHBENR + 0x02]
    ldr     r1, = DFU_BOOTSTRAP_GPIO
    ldr     r2, [r1, GPIO_MODER]
    ldr     r3, = (0x03 << (DFU_BOOTSTRAP_PIN * 2))
    bics    r2, r3
    str     r2, [r1, GPIO_MODER]
    ldr     r2, [r1, GPIO_PUPDR]
    bics    r2, r3
#if (DFU_BOOTSTRAP_PULL == _DISABLE)
    ldr     r3, = (0x00 << (DFU_BOOTSTRAP_PIN * 2))
#elif ((DFU_BOOTSTRAP_PULL == _LOW) || ((DFU_BOOTSTRAP_PULL == _AUTO) && (DFU_BOOTSTRAP_LEVEL == _HIGH)))
    ldr     r3, = (0x02 << (DFU_BOOTSTRAP_PIN * 2))
#else
    ldr     r3, = (0x01 << (DFU_BOOTSTRAP_PIN * 2))
#endif
    orrs    r2, r3
    str     r2, [r1, GPIO_PUPDR]
/* checking bootstrap pin */
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
    beq     .L_start_boot
    cmp     r4, 0x10
    bne     .L_scan_bootstrap
#endif

#if (DFU_VERIFY_CHECKSUM != _DISABLE)
    ldr     r0, = _APP_START
    ldr     r1, = _APP_END
    subs    r1, r0
    bl      validate_checksum
    cbz     r0, .L_start_boot
#endif

/* Reset and start app */
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
    ldr     r1, = __etext
    ldr     r2, = __data_start__
    ldr     r3, = __data_end__
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

#if defined(STM32F373xC)
/* Enabling AF 0x0E for PA11, PA12 */
    movs    r2, 0x02
    strb    r2, [r5, RCC_AHBENR + 2]
    ldr     r3, =GPIOA
    movs    r2, 0xEE
    ldr     r1, [r3, GPIO_AFRH]
    bfi     r1, r2, 12, 8
    str     r1, [r3, GPIO_AFRH]
    movs    r2, 0x0A
    ldr     r1, [r3, GPIO_MODER]
    bfi     r1, r2, 22, 4
    str     r1, [r3, GPIO_MODER]
#endif
#if (DFU_SEAL_LEVEL != 0)
    ldr     r3, = seal_flash
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
/* R0 <- addrss to flash
 * R1 <- buffer
 * R2 <- block size (nonzero less than 0x40)
 * R0 -> DFU_STATUS
 */
program_flash:
    push    {r4, r5, lr}
/* checking halfword alignment */
    lsrs    r4, r0, 0x01
    bcs     Err_unaligned
/* unlocking flash */
    ldr     r3, = FLASH_R_BASE
    ldr     r4, = FLASH_KEY0
    ldr     r5, = FLASH_KEY1
    str     r4, [r3, FLASH_KEYR]
    str     r5, [r3, FLASH_KEYR]
/* main flash loop */
.L_flash_loop:
    subs    r2, 0x02
    blt     Err_done
/* check for the page start (2k page)*/
    lsls    r4, r0, 21
    bne     .L_do_write
/* erasing page */
    movs    r4, 0x02                // PER
    str     r4, [r3, FLASH_CR]
    str     r0, [r3, FLASH_AR]
    movs    r4, 0x42                // PER + START
    str     r4, [r3, FLASH_CR]
    bl      wait_prog_done
    bcc     Err_erase
.L_do_write:
    mov     r4, 0x01                // PG
    str     r4, [r3, FLASH_CR]
    ldrh    r5, [r1]
    strh    r5, [r0]
    bl      wait_prog_done
    bcc     Err_prog
    ldrh    r4, [r0]
    cmp     r5, r4
    bne     Err_verify
    adds    r0, 0x02
    adds    r1, 0x02
    b       .L_flash_loop
Err_done:
    movs    r0, 0x00        //OK
    b       .L_exit
Err_unaligned:
    movs    r0, 0x03        //errWRITE (unaligned access)
    b       .L_exit
Err_erase:
    movs    r0, 0x04        //errERASE
    b       .L_exit
Err_prog:
    movs    r0, 0x06        //errPROG
    b       .L_exit
Err_verify:
    movs    r0, 0x07        //errVERIFY
.L_exit:
/* clear FLASH_SR */
    movs    r4, 0x64
    str     r4, [r3, FLASH_SR]
/* locking flash */
    movs    r4, 0x80
    str     r4, [r3, FLASH_CR]
    pop     {r4, r5, pc}
    .size program_flash, . - program_flash


    .thumb_func
    .type wait_prog_done, %function
wait_prog_done:
    ldr     r4, [r3, FLASH_SR]
    lsrs    r4, 0x01                //BSY -> CF
    bcs     wait_prog_done          //wait BSY low
    lsrs    r4, 0x05                //EOP -> CF
    ldr     r4, [r3, FLASH_SR]
    str     r4, [r3, FLASH_SR]     // clean FLASH_SR
    bx      lr


#if (DFU_SEAL_LEVEL != 0)
    .thumb_func
    .type seal_flash, %function
/* R0 -> DFU_STATUS */
seal_flash:
    ldr     r3, = FLASH_R_BASE
    ldr     r0, [r3, FLASH_OBR]
    lsrs    r0, #2                  //RDPRT -> CF
    bcc     .L_seal
    bx      lr
.L_seal:
/* unlocking flash */
    ldr     r1, = FLASH_KEY0
    ldr     r2, = FLASH_KEY1
    str     r1, [r3, FLASH_KEYR]
    str     r2, [r3, FLASH_KEYR]
/* unlocking OPTION programming */
    str     r1, [r3, FLASH_OPTKEYR]
    str     r2, [r3, FLASH_OPTKEYR]
/* erasing OPTION data. */
    movs    r1, 0x20                // OPTER
    str     r1, [r3, FLASH_CR]
    movs    r1, 0x60                // START + OPTER
    str     r1, [r3, FLASH_CR]
    bl      wait_prog_done
/* set RDP */
    movs    r1, 0x10
    str     r1, [r3, FLASH_CR]
    ldr     r0, = FLASH_OP_BASE
    ldr     r1, = 0x33CC
    strh    r1, [r0, 0x00]
    bl      wait_prog_done
/* reset */
    ldr     r1,= 0x2000             //OBL_LAUNCH
    str     r1, [r3, FLASH_CR]
    b       .                       //loop forever till reset
    .size seal_flash, . - seal_flash
#endif

    .pool

    .end
