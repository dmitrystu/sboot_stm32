#include "config.h"
#define FLASH_R_BASE    0x40023C00
#define FLASH_ACR       0x00
#define FLASH_PECR      0x04
#define FLASH_PEKEYR    0x0C
#define FLASH_PRGKEYR   0x10
#define FLASH_OPTKEYR   0x14
#define FLASH_SR        0x18
#define FLASH_OPTR      0x1C
#define FLASH_PEKEY0    0x89ABCDEF
#define FLASH_PEKEY1    0x02030405
#define FLASH_PRGKEY0   0x8C9DAEBF
#define FLASH_PRGKEY1   0x13141516
#define FLASH_OPTKEY0   0xFBEAD9C8
#define FLASH_OPTKEY1   0x24252627
#define FLASH_OB_BASE   0x1FF80000
#define FLASH_PAGESZ    0x100
#define FLASH_HP_MASK   0x7F

#define RCC_BASE        0x40023800
#define RCC_CR          0x00
#define RCC_CFGR        0x08
#define RCC_AHBRSTR     0x10
#define RCC_AHBENR      0x1C
#define RCC_APB1ENR     0x24

#define PWR_BASE        0x40007000
#define PWR_CR          0x00
#define PWR_CSR         0x04

#define GPIOA           0x40020000
#define GPIOB           0x40020400
#define GPIOC           0x40020800
#define GPIOD           0x40020C00
#define GPIOE           0x40021000
#define GPIOF           0x40021400
#define GPIOG           0x40021800
#define GPIOH           0x40021C00

#define SCB             0xE000ED00
#define SCB_VTOR        0x08
#define SCB_AIRCR       0x0C

#define GPIO_MODER      0x00
#define GPIO_OTYPER     0x04
#define GPIO_PUPDR      0x0C
#define GPIO_IDR        0x10

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
#else
    #error Incorrect DFU_BOOTSTRAP_GPIO. Check Config!!
#endif

#if ((DFU_BOOTSTRAP_PIN < 0) || (DFU_BOOTSTRAP_PIN > 15)) && (DFU_BOOTSTRAP_GPIO != _DISABLE)
    #error Incorrect DFU_BOOTSTRAP_PIN. Check config !!
#endif

#if ((DFU_BLOCKSZ % (FLASH_PAGESZ / 2)) != 0)
#error "DFU block sise must be multiple of flash halfpage size (0x80)"
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
/* STM32L100 startup clock is about 2.097MHz MSI
 * so, we need T(mS)*2097 ticks to make a required delay */
    ldr     r0, = (DFU_DBLRESET_MS * 2097 / 3)
.L_rst_delay:
    subs    r0, 1               //+1 tick
    bhs     .L_rst_delay        //+2 ticks, 3 ticks/cycle
/* Clearing bootkey and continue */
    str     r3, [r1]
#endif
/* Setup clock 24Mhz HSI PLL for USB use
 * All registers means their reset values
 */

/* Enabling PWR interface */
    ldr     r5, = RCC_BASE
    movs    r1, 0x01
    lsls    r1, 28
    str     r1, [r5, RCC_APB1ENR]
/* Set Power range 2 */
    ldr     r0, = PWR_BASE
    lsrs    r1, 16
    str     r1, [r0, PWR_CR]
.L_wait_pw_set:
    ldr     r1, [r0, PWR_CSR]
    lsrs    r1, 5                  //VOSF->CF
    bcs     .L_wait_pw_set
/* Set latency 1 */
    ldr     r0, = FLASH_R_BASE
    movs    r1, 0x04
    str     r1, [r0, FLASH_ACR]
    movs    r1, 0x05
    str     r1, [r0, FLASH_ACR]
/* set PLL 6/4 HSI */
    movs    r1, 0xC8
    strb    r1, [r5, RCC_CFGR + 2] //use byte access
/* enable HSI16 */
    movs    r1, 0x01
    strb    r1, [r5, RCC_CR + 0]   //set HSI on
.L_wait_HSI:
    ldrb    r2, [r5, RCC_CR + 0]
    lsrs    r2, 2                  //HSIRDYF -> CF
    bcc     .L_wait_HSI
/* enable PLL */
    strb    r1, [r5, RCC_CR + 3]   //PLL ON
.L_wait_PLL:
    ldrb    r2, [r5, RCC_CR + 3]
    lsrs    r2, 2                  //PLLRDYF -> CF
    bcc     .L_wait_PLL
/* set SW[1:0] to PLL */
    movs    r1, 0x03
    strb    r1, [r5, RCC_CFGR + 0]
    cbz     r4, .L_start_boot

#if (DFU_BOOTSTRAP_GPIO != _DISABLE)
/* checking bootstrap pin */
    ldr     r1, = DFU_BOOTSTRAP_GPIO
    movs    r2, BOOTSTRAP_RCC
    strb    r2, [r5, RCC_AHBENR]
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
    movs    r2, BOOTSTRAP_RCC
    strb    r2, [r5, RCC_AHBRSTR]
    movs    r2, 0x00
    strb    r2, [r5, RCC_AHBRSTR]
    strb    r2, [r5, RCC_AHBENR]
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
/* checking halfpage alignment */
    movs    r4, FLASH_HP_MASK
    tst     r4, r0
    bne     Err_unaligned
/* adjust block size to halfpage */
    adds    r5, r4, 0x01
    subs    r5, r2
    ands    r5, r4
    adds    r2, r5
/* unlock program enable */
    bl      unlock_pe
/* unlocking program memoty */
    ldr     r4, =FLASH_PRGKEY0
    ldr     r5, =FLASH_PRGKEY1
    str     r4, [r3, FLASH_PRGKEYR]
    str     r5, [r3, FLASH_PRGKEYR]
/* flash loop */
.L_flash_loop:
/* checking if page erase required */
    movs    r4, FLASH_HP_MASK
    lsls    r4, 0x01
    ands    r4, r0
    bne     .L_write_halfpage
/* do page erase */
    movs    r4, 0x41
    lsls    r4, 0x03       //ERASE | PROG
    str     r4, [r3, FLASH_PECR]
    movs    r4, 0x00
    str     r4, [r0]        //fake write to rom to start erase
    bl      wait_prog_done
    bcc     Err_erase
.L_write_halfpage:
    movs    r4, 0x81
    lsls    r4, 0x03       // FPRG | PROG
    str     r4, [r3, FLASH_PECR]
    movs    r5, 0x00
/* do halfpage write */
.L_hp_loop:
    ldr     r4, [r1, r5]
    str     r4, [r0, r5]
    adds    r5, 0x04
    cmp     r5, FLASH_HP_MASK
    blo     .L_hp_loop
    bl      wait_prog_done
    bcc     Err_prog
    movs    r4, 0x00
    str     r4, [r3, FLASH_PECR]
/* do hp verify */
.L_verify_loop:
    ldr     r4, [r0]
    ldr     r5, [r1]
    cmp     r4, r5
    bne     Err_verify
    adds    r0, 0x04
    adds    r1, 0x04
    subs    r2, 0x04
    movs    r4, FLASH_HP_MASK
    ands    r4, r2
    bne     .L_verify_loop
/* checking for done */
    cmp     r2, 0x00
    bne     .L_flash_loop
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
    movs    r4, 0x07
    str     r4, [r3, FLASH_PECR] // locking flash
    pop     {r4, r5, pc}
    .size program_flash, . - program_flash

/* wait for programming done */
/* return CF=0 if program failed */
    .thumb_func
    .type wait_prog_done, %function
wait_prog_done:
    ldr     r4, [r3, FLASH_SR]
    lsrs    r4, 0x01                //BSY -> CF
    bcs     wait_prog_done          //wait BSY low
    lsrs    r4, 0x02                //ENDHV -> CF
    bcc     wait_prog_done          //wait ENDHV high
    ldr     r4, [r3, FLASH_SR]      //reload FLASH_SR
    lsrs    r4, 0x02                //EOP -> CF
    //bcc     .L_wpd_exit
    movs    r4, 0x02                //clear EOP
    str     r4, [r3, FLASH_SR]
.L_wpd_exit:
    bx      lr
    .size wait_prog_done, . - wait_prog_done

/* unlock program enable function and set R3 to FLASH_R_BASE */
    .thumb_func
    .type unlock_pe, %function
unlock_pe:
    ldr     r3, = FLASH_R_BASE
    ldr     r4, = FLASH_PEKEY0
    ldr     r5, = FLASH_PEKEY1
    str     r4, [r3, FLASH_PEKEYR]
    str     r5, [r3, FLASH_PEKEYR]
    bx      lr
    .size unlock_pe, . - unlock_pe


    .thumb_func
    .globl program_eeprom
    .type program_eeprom, %function
/* R0 <- Address to flash
 * R1 <- Buffer
 * R2 <- block size (nonzero!)
 * R0 -> DFU STATUS
 */
program_eeprom:
    push    {r4, r5, lr}
/* unlock program enable */
    bl      unlock_pe
/* flash unlocked. let's do write using word write */
    movs    r4, 0x00
    str     r4, [r3, FLASH_PECR]
/* writing byte by byte */
.L_ee_write:
    ldr     r4, [r1]
    str     r4, [r0]
    ldr     r5, [r0]
    cmp     r5, r4
    bne     Err_verify
    adds    r0, 0x04
    adds    r1, 0x04
    subs    r2, 0x04
    bgt     .L_ee_write
    b       Err_done
    .size   program_eeprom, . - program_eeprom

#if (DFU_SEAL_LEVEL != 0)
    .thumb_func
    .type seal_flash, %function
/* R0 -> DFU_STATUS */
seal_flash:
    push    {r4, r5, lr}
    bl      unlock_pe
    ldr     r0, [r3, FLASH_OPTR]
    uxtb    r1, r0
    eors    r0, r1
#if (DFU_SEAL_LEVEL == 2)
    #warning Protection Level 2 is an irreversible.
    cmp     r1, 0xCC
    beq     .L_seal_end
    adds    r0, 0xCC
#else
    cmp     r1, 0xAA
    bne     .L_seal_end
    adds    r0, 0x81
#endif
/* unlocking flash and option bytes */
    ldr     r4, = FLASH_OPTKEY0
    ldr     r5, = FLASH_OPTKEY1
    str     r4, [r3, FLASH_OPTKEYR]
    str     r5, [r3, FLASH_OPTKEYR]
/* preparing OBL data R4:R5*/
    mvns    r4, r0
    lsls    r4, 0x10
    uxth    r5, r0
    orrs    r4, r5
    lsrs    r0, 0x10
    mvns    r5, r0
    lsls    r5, 0x10
    orrs    r5, r0
/* program user option */
    ldr     r1, = FLASH_OB_BASE
    str     r4, [r1, 0x00]
    str     r5, [r1, 0x04]
    bl      wait_prog_done
/* do lock and exit */
    bcc     Err_prog
.L_seal_end:
    b       Err_done
    .size seal_flash, . - seal_flash
#endif
    .pool

    .end
