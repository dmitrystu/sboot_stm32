#include "config.h"
#define FLASH_R_BASE    0x40022000
#define FLASH_ACR       0x00
#define FLASH_KEYR      0x08
#define FLASH_OPTKEYR   0x0C
#define FLASH_SR        0x10
#define FLASH_CR        0x14
#define FLASH_OPTR      0x20
#define FLASH_PRGKEY0   0x45670123
#define FLASH_PRGKEY1   0xCDEF89AB
#define FLASH_OPTKEY0   0x08192A3B
#define FLASH_OPTKEY1   0x4C5D6E7F

#define RCC_BASE        0x40021000
#define RCC_CR          0x00
#define RCC_CFGR        0x08
#define RCC_PLLCFGR     0x0C
#define RCC_AHB2RSTR    0x2C
#define RCC_AHB2ENR     0x4C
#define RCC_CCIPR       0x88
#define RCC_CRRCR       0x98


#define GPIOA           0x48000000
#define GPIOB           0x48000400
#define GPIOC           0x48000800
#define GPIOD           0x48000C00
#define GPIOE           0x48001000
#define GPIOF           0x48001400
#define GPIOG           0x48001800
#define GPIO_MODER      0x00
#define GPIO_PUPDR      0x0C
#define GPIO_IDR        0x10
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

#if (DFU_BOOTKEY_ADDR == _AUTO) || (DFU_BOOTKEY_ADDR == _DISABLE)
    #define _KEY_ADDR   __stack
#else
    #define _KEY_ADDR   DFU_BOOTKEY_ADDR
#endif

#if (DFU_BOOTSTRAP_GPIO == _DISABLE)
    #define BOOTSTRAP_RCC   0x00
#elif (DFU_BOOTSTRAP_GPIO == GPIOA)
    #define BOOTSTRAP_RCC   0x01
#elif (DFU_BOOTSTRAP_GPIO == GPIOB)
    #define BOOTSTRAP_RCC   0x02
#elif (DFU_BOOTSTRAP_GPIO == GPIOC)
    #define BOOTSTRAP_RCC   0x04
#elif (DFU_BOOTSTRAP_GPIO == GPIOD)
    #define BOOTSTRAP_RCC   0x08
#elif (DFU_BOOTSTRAP_GPIO == GPIOE)
    #define BOOTSTRAP_RCC   0x10
#elif (DFU_BOOTSTRAP_GPIO == GPIOF)
    #define BOOTSTRAP_RCC   0x20
#elif (DFU_BOOTSTRAP_GPIO == GPIOG)
    #define BOOTSTRAP_RCC   0x40
#else
    #error Incorrect DFU_BOOTSTRAP_GPIO. Check Config!!
#endif

#if ((DFU_BOOTSTRAP_PIN < 0) || (DFU_BOOTSTRAP_PIN > 15)) && (DFU_BOOTSTRAP_GPIO != _DISABLE)
    #error Incorrect DFU_BOOTSTRAP_PIN. Check config !!
#endif

    .syntax unified
    .cpu cortex-m4
    .thumb

    .section .isr_vector
    .align 2
    .globl __isr_vector
__isr_vector:
    .long   __stack
    .long   Reset_Handler
    .long   NMI_Handler
    .long   HardFault_Handler
    .long   MemManage_Handler
    .long   BusFault_Handler
    .long   UsageFault_Handler
    .long   0
    .long   0
    .long   0
    .long   0
    .long   SVC_Handler
    .long   DebugMon_Handler
    .long   0
    .long   PendSV_Handler
    .long   SysTick_Handler
/* Peripheral interrupts are not used */
    .size    __isr_vector, . - __isr_vector

    .section    .text
    .thumb_func

    .globl  System_Reset
    .type   System_Reset, %function

    .globl  Reset_Handler
    .type   Reset_Handler, %function
Reset_Handler:
    ldr     r1, = _KEY_ADDR
    ldr     r2, = DFU_BOOTKEY
    movs    r3, 0x00
    ldr     r4, [r1]
    str     r3, [r1]
    eors    r4, r2
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
/* STM32G4 startup clock is about 16.0MHz HSI
 * so, we need T(mS)*4000 ticks to make a required delay */
    ldr     r0, = (DFU_DBLRESET_MS * 16000 / 3)
.L_rst_delay:
    subs    r0, 1               //+1 tick
    bhs     .L_rst_delay        //+2 ticks, 3 ticks/cycle
/* Clearing bootkey and continue */
    str     r3, [r1]
#endif
/* setup clock  */
/* On reset we are on Power Range1 Flash WS = 1 */
/* setup clock PLL Fvco=288MHz Fq = 48MHz, Fr = 36MHz from 16MHz HSI */
    ldr     r5, = RCC_BASE
    ldr     r1, = ((0x07 << 24) | (0x05 << 20) | (0x48 << 8) | (0x03 << 4) | (0x02 << 0))
    ldr     r2, = ((0x07 << 24) | (0x07 << 20) | (0x7F << 8) | (0x0F << 4) | (0x03 << 0))
    ldr     r0, [r5, RCC_PLLCFGR]
    bics    r0, r2
    orrs    r0, r1
    str     r0, [r5, RCC_PLLCFGR]
    movs    r1, 0x01
    ldrb    r0, [r5, RCC_CR + 0x03]
    orrs    r0, r1
    strb    r0, [r5, RCC_CR + 0x03]
.L_wait_pll:
    ldrb    r0, [r5, RCC_CR + 0x03]
    lsrs    r0, 2
    bcc     .L_wait_pll
/* switching SYSCLK from HSI to PLL */
    movs    r0, 0x03
    strb    r0, [r5, RCC_CFGR + 0x00]
/* selecting PLLQ as USB48MHZ */
    movs    r0, 0x08
    strb    r0, [r5, RCC_CCIPR + 0x03]
    cbz     r4, .L_start_boot

#if (DFU_BOOTSTRAP_GPIO != _DISABLE)
/* checking bootstrap pin */
    ldr     r1, = DFU_BOOTSTRAP_GPIO
    movs    r2,  BOOTSTRAP_RCC
    strb    r2, [r5, RCC_AHB2ENR]
    movs    r2, 0x03
    lsls    r2, (DFU_BOOTSTRAP_PIN * 2)
    ldr     r3, [r1, GPIO_MODER]
    bics    r3, r2
    str     r3, [r1, GPIO_MODER]
    ldr     r3, [r1, GPIO_PUPDR]
    bics    r3, r2
#if (DFU_BOOTSTRAP_PULL == _DISABLE)
    movs    r2, 0x00
#elif ((DFU_BOOTSTRAP_PULL == _LOW) || ((DFU_BOOTSTRAP_PULL == _AUTO) && (DFU_BOOTSTRAP_LEVEL == _HIGH)))
    movs    r2, 0x02        //pulldown
#else
    movs    r2, 0x01        //pullup
#endif
    lsls    r2, (DFU_BOOTSTRAP_PIN * 2)
    orrs    r3, r2
    str     r3, [r1, GPIO_PUPDR]
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
    movs    r2, BOOTSTRAP_RCC
    str     r2, [r5, RCC_AHB2RSTR]
    movs    r2, 0x00
    str     r2, [r5, RCC_AHB2RSTR]
    str     r2, [r5, RCC_AHB2ENR]
    cbz     r4, .L_start_boot
#endif

#if (DFU_VERIFY_CHECKSUM != _DISABLE)
    ldr     r0, = _APP_START
    ldr     r1, = __romend
    subs    r1, r0
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

/* starting bootloader */
.L_start_boot:
    ldr     r1, =__etext
    ldr     r2, =__data_start__
    ldr     r3, =__data_end__
    subs    r3, r2
    ble     .L_clear_bss
.L_copy_data:
    subs    r3, 0x04
    ldr     r0, [r1, r3]
    str     r0, [r2, r3]
    bgt     .L_copy_data
.L_clear_bss:
    ldr     r1, = __bss_start__
    ldr     r2, = __bss_end__
    movs    r3, 0
.L_bss_loop:
    str     r3, [r1]
    adds    r1, 0x04
    cmp     r1, r2
    bcc     .L_bss_loop
#if (DFU_SEAL_LEVEL != 0)
    ldr     r3, = seal_flash
    blx     r3
#endif
/* jump to bootloader */
    bl      main

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

/* using RAM for this functions */
    .section .data
    .align 2
    .thumb_func
    .globl program_flash
    .type program_flash, %function
/* R0 <- addrss to flash
 * R1 <- buffer
 * R2 <- block size
 * R0 -> DFU_STATUS
 */
program_flash:
    push    {r4, r5, r6, lr}
/* checking doubleword alignment */
    movs    r4, 0x07
    tst     r4, r0
    bne     Err_unaligned
/* unlocking flash */
    ldr     r3, = FLASH_R_BASE
.L_flash_unlock:
    ldr     r4, [r3, FLASH_SR]
    lsls    r4, 16                 /* BSY->CF */
    bcs     .L_flash_unlock
    ldr     r4, = FLASH_PRGKEY0
    ldr     r5, = FLASH_PRGKEY1
    str     r4, [r3, FLASH_KEYR]
    str     r5, [r3, FLASH_KEYR]
    movs    r6, 0
.L_flash_loop:
/* checking end of block */
    cmp     r6, r2
    bhs     .L_do_verify
/* clean FLASH_SR */
    ldr     r4, [r3, FLASH_SR]
    str     r4, [r3, FLASH_SR]
    adds    r4, r0, r6
/* check for the page start (2k page) */
    lsls    r5, r4, 21
    bne     .L_do_write
#if defined(STM32G431xx) //Cat2
/* calculating PNB[6:0]: ADDR[17:11] -> CR[9:3] */
    lsrs    r4, 11
    bfi     r5, r4, 3, 7
#else // Cat3
/* check dual bank */
    ldr     r5, [r3, FLASH_OPTR]
    lsrs    r5, 23     // DBANK -> CF
    bcc     .L_single_bank
/* calculating PNB[6:0] and BKER for dual bank*/
/* ADDR[17:11] -> CR[9:3], ADDR[18] -> CR[11] */
    movs    r5, 0x00
    lsrs    r4, 11
    bfi     r5, r4, 3, 7
    lsrs    r4, 7
    bfi     r5, r4, 11, 1
    b       .L_do_erase
.L_single_bank:
/* check for the page start (4k page) */
    lsls    r5, r4, 20
    bne     .L_do_write
/* calculating PNB[6:0]: ADDR[18:12] -> CR[9:3] */
    lsrs    r4, 12
    bfi     r5, r4, 3, 7
#endif
/* erasing page */
.L_do_erase:
/* set PER */
    adds    r5, 0x02
    str     r5, [r3, FLASH_CR]
    movs    r4, 0x01
    strh    r4, [r3, FLASH_CR + 0x02]  /* set STRT */
    bl      wait_flash_ready
    bne     Err_erase
/* perform doubleword write */
.L_do_write:
    movs    r4, 0x01                   /* set PG */
    str     r4, [r3, FLASH_CR]
    ldr     r4, [r1, r6]
    str     r4, [r0, r6]
    adds    r6, 0x04
    ldr     r4, [r1, r6]
    str     r4, [r0, r6]
    adds    r6, 0x04
    bl      wait_flash_ready
    bne     Err_prog
    b      .L_flash_loop           /* if no errors */
.L_do_verify:
/* disabling programming */
    movs    r4, 0x00
    str     r4, [r3, FLASH_CR]
.L_verify_loop:
    subs    r2, 1
    bcc     Err_done
    ldrb    r4, [r0, r2]
    ldrb    r5, [r1, r2]
    cmp     r4, r5
    bne     Err_verify
    b      .L_verify_loop
/* all done */
Err_done:
    movs    r0, 0x00       //OK
    b       .L_exit
Err_unaligned:
    movs    r0, 0x03       // errWRITE (unaligned access)
    b       .L_exit
Err_erase:
    movs    r0, 0x04       //errERASE
    b       .L_exit
Err_prog:
    movs    r0, 0x06       //errPROG
    b       .L_exit
Err_verify:
    movs    r0, 0x07       //errVERIFY
.L_exit:
    movs    r4, 0x03
    lsls    r4, 30
    str     r4, [r3, FLASH_CR] // locking flash
    pop     {r4, r5, r6, pc}
    .size program_flash, . - program_flash


    .thumb_func
    .type   wait_flash_ready, %function
wait_flash_ready:
    ldr     r4, [r3, FLASH_SR]
    lsls    r4, 16         //BSY->CF
    bcs     wait_flash_ready
    lsrs    r4, 17         //EOP->CF
    bx      lr
    .size wait_flash_ready, . - wait_flash_ready

#if (DFU_SEAL_LEVEL != 0)
    .thumb_func
    .globl seal_flash
    .type seal_flash, %function
seal_flash:
    push    {r4, r5, r6, lr}
    ldr     r3, = FLASH_R_BASE
    ldrb    r1, [r3, FLASH_OPTR]
#if (DFU_SEAL_LEVEL == 2)
#warning Protection Level 2 is an irreversible !!
    cmp     r1, 0xCC
    beq     Err_done
    movs    r0, 0xCC
#else
    cmp     r1, 0xAA
    bne     Err_done
    movs    r0, 0x18
#endif
    ldr     r4, = FLASH_PRGKEY0
    ldr     r5, = FLASH_PRGKEY1
    str     r4, [r3, FLASH_KEYR]
    str     r5, [r3, FLASH_KEYR]
    ldr     r4, = FLASH_OPTKEY0
    ldr     r5, = FLASH_OPTKEY1
    str     r4, [r3, FLASH_OPTKEYR]
    str     r5, [r3, FLASH_OPTKEYR]
/* clean FLASH_SR */
    ldr     r4, [r3, FLASH_SR]
    str     r4, [r3, FLASH_SR]
/* modify OPTR */
    strb    r0, [r3, FLASH_OPTR]
/* set OPT_STRT */
    movs    r4, 0x02
    strb    r4, [r3, FLASH_CR + 0x02]
    bl      wait_flash_ready
    bne     Err_prog
    b       Err_done
    .size seal_flash, . - seal_flash
#endif

    .pool
    .end
