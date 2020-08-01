#include "config.h"
#define FLASH_R_BASE    0x40023C00
#define FLASH_ACR       0x00
#define FLASH_KEYR      0x04
#define FLASH_OPTKEYR   0x08
#define FLASH_SR        0x0C
#define FLASH_CR        0x10
#define FLASH_OPTCR     0x14
#define FLASH_PRGKEY0   0x45670123
#define FLASH_PRGKEY1   0xCDEF89AB
#define FLASH_OPTKEY0   0x08192A3B
#define FLASH_OPTKEY1   0x4C5D6E7F

#define RCC_BASE        0x40023800
#define RCC_CR          0x00
#define RCC_PLLCFGR     0x04
#define RCC_CFGR        0x08
#define RCC_AHB1RSTR    0x10
#define RCC_AHB1ENR     0x30


#define GPIOA           0x40020000
#define GPIOB           0x40020400
#define GPIOC           0x40020800
#define GPIOD           0x40020C00
#define GPIOE           0x40021000
#define GPIOF           0x40021400
#define GPIOG           0x40021800
#define GPIOH           0x40021C00
#define GPIOI           0x40022000
#define GPIOJ           0x40022400
#define GPIOK           0x40022800

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
    #define BOOTSTRAP_RCC   0x000
#elif (DFU_BOOTSTRAP_GPIO == GPIOA)
    #define BOOTSTRAP_RCC   0x001
#elif (DFU_BOOTSTRAP_GPIO == GPIOB)
    #define BOOTSTRAP_RCC   0x002
#elif (DFU_BOOTSTRAP_GPIO == GPIOC)
    #define BOOTSTRAP_RCC   0x004
#elif (DFU_BOOTSTRAP_GPIO == GPIOD)
    #define BOOTSTRAP_RCC   0x008
#elif (DFU_BOOTSTRAP_GPIO == GPIOE)
    #define BOOTSTRAP_RCC   0x010
#elif (DFU_BOOTSTRAP_GPIO == GPIOH)
    #define BOOTSTRAP_RCC   0x020
#elif (DFU_BOOTSTRAP_GPIO == GPIOF)
    #define BOOTSTRAP_RCC   0x040
#elif (DFU_BOOTSTRAP_GPIO == GPIOG)
    #define BOOTSTRAP_RCC   0x080
#elif (DFU_BOOTSTRAP_GPIO == GPIOI)
    #define BOOTSTRAP_RCC   0x100
#elif (DFU_BOOTSTRAP_GPIO == GPIOJ)
    #define BOOTSTRAP_RCC   0x200
#elif (DFU_BOOTSTRAP_GPIO == GPIOK)
    #define BOOTSTRAP_RCC   0x400
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
/* STM32F4 startup clock is about 16 MHz HSI
 * so, we need T(mS)*16000 ticks to make a required delay */
    ldr     r0, = (DFU_DBLRESET_MS * 16000 / 3)
.L_rst_delay:
    subs    r0, 1              //+1 tick
    bhs     .L_rst_delay        //+2 ticks, 3 ticks/cycle
/* Clearing bootkey and continue */
    str     r3, [r1]
#endif

/* setup clock */
    ldr     r5, = RCC_BASE
/* Adjusting flash latency */
    ldr     r2, = FLASH_R_BASE
    movs    r1, 2
    str     r1, [r2, FLASH_ACR]
/* setup clock PLL Fvco=144MHz Fq = 48MHz, Fp = 72MHz from 16MHz HSI */
    ldr     r1, = ((0x0F << 24) | (0x01 << 22) | (0x03 << 16) | (0x1FF << 6) | (0x3F << 0))
    ldr     r2, = ((0x03 << 24) | (0x00 << 22) | (0x00 << 16) | (0x048 << 6) | (0x08 << 0))
    ldr     r3, [r5, RCC_PLLCFGR]
    bics    r3, r1
    orrs    r3, r2
    str     r3, [r5, RCC_PLLCFGR]
/* swithcing on PLL */
    movs    r1, 0x01
    ldrb    r3, [r5, RCC_CR + 0x03]
    orrs    r3, r1
    strb    r3, [r5, RCC_CR + 0x03]
.L_wait_pll:
    ldrb    r3, [r5, RCC_CR + 0x03]
    lsrs    r3, 0x02                //PLLRDY -> CF
    bcc     .L_wait_pll
/* switching SYSCLK from HSI to PLL */
    movs    r1, 0x02
    ldrb    r3, [r5, RCC_CFGR + 0x00]
    orrs    r3, r1
    strb    r3, [r5, RCC_CFGR + 0x00]
    cbz     r4, .L_start_boot

#if (DFU_BOOTSTRAP_GPIO != _DISABLE)
/* checking bootstrap pin */
    ldr     r1, = DFU_BOOTSTRAP_GPIO
    ldr     r2, = BOOTSTRAP_RCC
    strh    r2, [r5,  RCC_AHB1ENR + 0x00]
    movs    r2, 0x03
    lsls    r2, (DFU_BOOTSTRAP_PIN * 2)
    ldr     r3, [r1,  GPIO_MODER]
    bics    r3, r2
    str     r3, [r1,  GPIO_MODER]
    ldr     r3, [r1,  GPIO_PUPDR]
    bics    r3, r2
#if (DFU_BOOTSTRAP_PULL == _DISABLE)
    movs    r2, 0x00
#elif ((DFU_BOOTSTRAP_PULL == _LOW) || ((DFU_BOOTSTRAP_PULL == _AUTO) && (DFU_BOOTSTRAP_LEVEL == _HIGH)))
    movs    r2, 0x02       //pulldown
#else
    movs    r2, 0x01       //pullup
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
    ldr     r2, = BOOTSTRAP_RCC
    strh    r2, [r5, RCC_AHB1RSTR + 0x00]
    movs    r2, 0x00
    strb    r2, [r5, RCC_AHB1RSTR]
    strb    r2, [r5, RCC_AHB1ENR]
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
    mvn     r2, r2
    str     r2, [r1]
System_Reset:
    dsb
    ldr     r1, = SCB
    ldr     r2, = 0x05FA0004;
    str     r2, [r1, SCB_AIRCR]
    b .

/* starting bootloader */
.L_start_boot:
    ldr     r1, = __etext
    ldr     r2, = __data_start__
    ldr     r3, = __data_end__
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
#if defined(USBD_PRIMARY_OTGHS)
/* Enabling USB pins GPIOB14 GPIOB15 AF12*/
    movs    r1, 0x02
    strb    r1, [r5, RCC_AHB1ENR]
    ldr     r0, = GPIOB
    movs    r1, 0xA0
    strb    r1, [r0, GPIO_MODER + 0x03]
    movs    r1, 0xCC
    strb    r1, [r0, GPIO_AFRH + 0x03]
#else
/* Enabling USB pins GPIOA11 GPIOA12 AF10*/
    movs    r1, 0x01
    strb    r1, [r5, RCC_AHB1ENR]
    ldr     r0, = GPIOA
    ldr     r1, [r0, GPIO_MODER]
    movs    r2, 0xAA
    bfi     r1, r2, 22, 4
    str     r1, [r0, GPIO_MODER]
    lsls    r2, #12
    str     r2, [r0, GPIO_AFRH]
#endif
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
    push    {r4, r5, r6, r7, r8, lr}
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
/* check for the page start (16k page)*/
    mov     r4, r6
    adds    r4, r0
    lsls    r5, r4, 18
    bne     .L_do_write
/* checking Sectors */
    ldr     r5, [r3, FLASH_OPTCR]
    ldr     r8, = (snglbank - 0x04)
    lsls    r5, 2          /* DB1M -> CF */
    bcc     .L_sectors_start
    ldr     r8, = (dualbank - 0x04)
.L_sectors_start:
    lsrs    r5, r4, 12
.L_sectors:
    adds    r8, 0x04
    ldrh    r7, [r8, 0x00]
    cmp     r7, r5
    bhi     .L_do_write     /* not a sector start */
    bne     .L_sectors
/* do sector erase. put SNB | SER to R5 */
    ldrh    r5, [r8, 0x02]
    strb    r5, [r3, #FLASH_CR + 0x00]
/* set STRT to activate sector erase */
    movs    r5, 0x01
    strb    r5, [r3, FLASH_CR + 0x02]
    bl      wait_flash_ready
    bne     Err_erase

/* perform word write */
.L_do_write:
    ldr     r4, = 0x0201           /* set PSIZE=2, PG */
    str     r4, [r3, FLASH_CR]
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
    pop     {r4, r5, r6, r7, r8, pc}
    .size program_flash, . - program_flash


    .thumb_func
    .type   wait_flash_ready, %function
wait_flash_ready:
    ldr     r4, [r3, #FLASH_SR]
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
    push    {r4, lr}
    movs    r0, 0x00       //OK
    ldr     r3, = FLASH_R_BASE
    ldrb    r1, [r3, FLASH_OPTCR + 0x01]
#if (DFU_SEAL_LEVEL == 2)
#warning Protection Level 2 is an irreversible !!
    cmp     r1, 0xCC
    beq     .L_seal_done
    movs    r2, 0xCC
#else
    cmp     r1, 0xAA
    bne     .L_seal_done
    movs    r2, 0x18
#endif
    ldr     r1, = FLASH_PRGKEY0
    str     r1, [r3, FLASH_KEYR]
    ldr     r1, = FLASH_PRGKEY1
    str     r1, [r3, FLASH_KEYR]
    ldr     r1, = FLASH_OPTKEY0
    str     r1, [r3, FLASH_OPTKEYR]
    ldr     r1, = FLASH_OPTKEY1
    str     r1, [r3, FLASH_OPTKEYR]
/* clean FLASH_SR */
    ldr     r1, [r3, FLASH_SR]
    str     r1, [r3, FLASH_SR]
/* modify RDP */
    strb    r2, [r3, FLASH_OPTCR + 0x01]
/* set OPTSTRT */
    movs    r1, 0x02
    ldrb    r2, [r3, FLASH_OPTCR + 0x00]
    orrs    r2, r1
    strb    r2, [r3, FLASH_OPTCR + 0x00]
    bl      wait_flash_ready
    beq     .L_seal_done
    movs    r0, 0x06       //errPROG
.L_seal_done:
    pop     {r4, pc}
    .size seal_flash, . - seal_flash
#endif

/* Bank numbering: Sector Start >> 12, FLASH_CR (SNB | SER) */
/* 1M single bank or 2M dual bank DB1M = 0 */
snglbank:
    .short  0x8000, (0x00 << 3) | 0x02  /* sector  0  16k */
    .short  0x8004, (0x01 << 3) | 0x02  /* sector  1  16k */
    .short  0x8008, (0x02 << 3) | 0x02  /* sector  2  16k */
    .short  0x800C, (0x03 << 3) | 0x02  /* sector  3  16k */
    .short  0x8010, (0x04 << 3) | 0x02  /* sector  4  64k */
    .short  0x8020, (0x05 << 3) | 0x02  /* sector  5 128k */
    .short  0x8040, (0x06 << 3) | 0x02  /* sector  6 128k */
    .short  0x8060, (0x07 << 3) | 0x02  /* sector  7 128k */
    .short  0x8080, (0x08 << 3) | 0x02  /* sector  8 128k */
    .short  0x80A0, (0x09 << 3) | 0x02  /* sector  9 128k */
    .short  0x80C0, (0x0A << 3) | 0x02  /* sector 10 128k */
    .short  0x80E0, (0x0B << 3) | 0x02  /* sector 11 128k */
    .short  0x8100, (0x10 << 3) | 0x02  /* sector 12  16k */
    .short  0x8104, (0x11 << 3) | 0x02  /* sector 13  16k */
    .short  0x8108, (0x12 << 3) | 0x02  /* sector 14  16k */
    .short  0x810C, (0x13 << 3) | 0x02  /* sector 15  16k */
    .short  0x8110, (0x14 << 3) | 0x02  /* sector 16  64k */
    .short  0x8120, (0x15 << 3) | 0x02  /* sector 17 128k */
    .short  0x8140, (0x16 << 3) | 0x02  /* sector 18 128k */
    .short  0x8160, (0x17 << 3) | 0x02  /* sector 19 128k */
    .short  0x8180, (0x18 << 3) | 0x02  /* sector 20 128k */
    .short  0x81A0, (0x19 << 3) | 0x02  /* sector 21 128k */
    .short  0x81C0, (0x1A << 3) | 0x02  /* sector 22 128k */
    .short  0x81E0, (0x1B << 3) | 0x02  /* sector 23 128k */
    .short  0xFFFF
/* 1M dual DB1M = 1 */
dualbank:
    .short  0x8000, (0x00 << 3) | 0x02  /* sector  0  16k */
    .short  0x8004, (0x01 << 3) | 0x02  /* sector  1  16k */
    .short  0x8008, (0x02 << 3) | 0x02  /* sector  2  16k */
    .short  0x800C, (0x03 << 3) | 0x02  /* sector  3  16k */
    .short  0x8010, (0x04 << 3) | 0x02  /* sector  4  64k */
    .short  0x8020, (0x05 << 3) | 0x02  /* sector  5 128k */
    .short  0x8040, (0x06 << 3) | 0x02  /* sector  6 128k */
    .short  0x8060, (0x07 << 3) | 0x02  /* sector  7 128k */
    .short  0x8080, (0x10 << 3) | 0x02  /* sector 12  16k */
    .short  0x8084, (0x11 << 3) | 0x02  /* sector 13  16k */
    .short  0x8088, (0x12 << 3) | 0x02  /* sector 14  16k */
    .short  0x808C, (0x13 << 3) | 0x02  /* sector 15  16k */
    .short  0x8090, (0x14 << 3) | 0x02  /* sector 16  64k */
    .short  0x80A0, (0x15 << 3) | 0x02  /* sector 17 128k */
    .short  0x80C0, (0x16 << 3) | 0x02  /* sector 18 128k */
    .short  0x80E0, (0x17 << 3) | 0x02  /* sector 19 128k */
    .short  0xFFFF

    .pool
    .end
