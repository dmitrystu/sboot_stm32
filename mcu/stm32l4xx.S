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
#define RCC_AHB2RSTR    0x2C
#define RCC_AHB2ENR     0x4C
#define RCC_APB1ENR1    0x58
#define RCC_CCIPR       0x88

#define PWR_BASE        0x40007000
#define PWR_CR1         0x00
#define PWR_CR2         0x04
#define PWR_SR2         0x14

#define GPIOA           0x48000000
#define GPIOB           0x48000400
#define GPIOC           0x48000800
#define GPIOD           0x48000C00
#define GPIOE           0x48001000
#define GPIOF           0x48001400
#define GPIOG           0x48001800
#define GPIOH           0x48001C00

#define GPIO_MODER      0x00
#define GPIO_PUPDR      0x0C
#define GPIO_IDR        0x10
#define GPIO_AFRL       0x20
#define GPIO_AFRH       0x24

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

#if ( (defined(DFU_VERIFY_CHECKSUM) && (DFU_VERIFY_CHECKSUM != _DISABLE) ) )
#if ( defined(DFU_CHECKSUM_TYPE) && (DFU_CHECKSUM_TYPE==_FAST) )
    .section    .text
crc32table:
    .word 0x00000000,0x77073096,0xEE0E612C,0x990951BA
    .word 0x076DC419,0x706AF48F,0xE963A535,0x9E6495A3
    .word 0x0EDB8832,0x79DCB8A4,0xE0D5E91E,0x97D2D988
    .word 0x09B64C2B,0x7EB17CBD,0xE7B82D07,0x90BF1D91
    .word 0x1DB71064,0x6AB020F2,0xF3B97148,0x84BE41DE
    .word 0x1ADAD47D,0x6DDDE4EB,0xF4D4B551,0x83D385C7
    .word 0x136C9856,0x646BA8C0,0xFD62F97A,0x8A65C9EC
    .word 0x14015C4F,0x63066CD9,0xFA0F3D63,0x8D080DF5
    .word 0x3B6E20C8,0x4C69105E,0xD56041E4,0xA2677172
    .word 0x3C03E4D1,0x4B04D447,0xD20D85FD,0xA50AB56B
    .word 0x35B5A8FA,0x42B2986C,0xDBBBC9D6,0xACBCF940
    .word 0x32D86CE3,0x45DF5C75,0xDCD60DCF,0xABD13D59
    .word 0x26D930AC,0x51DE003A,0xC8D75180,0xBFD06116
    .word 0x21B4F4B5,0x56B3C423,0xCFBA9599,0xB8BDA50F
    .word 0x2802B89E,0x5F058808,0xC60CD9B2,0xB10BE924
    .word 0x2F6F7C87,0x58684C11,0xC1611DAB,0xB6662D3D
    .word 0x76DC4190,0x01DB7106,0x98D220BC,0xEFD5102A
    .word 0x71B18589,0x06B6B51F,0x9FBFE4A5,0xE8B8D433
    .word 0x7807C9A2,0x0F00F934,0x9609A88E,0xE10E9818
    .word 0x7F6A0DBB,0x086D3D2D,0x91646C97,0xE6635C01
    .word 0x6B6B51F4,0x1C6C6162,0x856530D8,0xF262004E
    .word 0x6C0695ED,0x1B01A57B,0x8208F4C1,0xF50FC457
    .word 0x65B0D9C6,0x12B7E950,0x8BBEB8EA,0xFCB9887C
    .word 0x62DD1DDF,0x15DA2D49,0x8CD37CF3,0xFBD44C65
    .word 0x4DB26158,0x3AB551CE,0xA3BC0074,0xD4BB30E2
    .word 0x4ADFA541,0x3DD895D7,0xA4D1C46D,0xD3D6F4FB
    .word 0x4369E96A,0x346ED9FC,0xAD678846,0xDA60B8D0
    .word 0x44042D73,0x33031DE5,0xAA0A4C5F,0xDD0D7CC9
    .word 0x5005713C,0x270241AA,0xBE0B1010,0xC90C2086
    .word 0x5768B525,0x206F85B3,0xB966D409,0xCE61E49F
    .word 0x5EDEF90E,0x29D9C998,0xB0D09822,0xC7D7A8B4
    .word 0x59B33D17,0x2EB40D81,0xB7BD5C3B,0xC0BA6CAD
    .word 0xEDB88320,0x9ABFB3B6,0x03B6E20C,0x74B1D29A
    .word 0xEAD54739,0x9DD277AF,0x04DB2615,0x73DC1683
    .word 0xE3630B12,0x94643B84,0x0D6D6A3E,0x7A6A5AA8
    .word 0xE40ECF0B,0x9309FF9D,0x0A00AE27,0x7D079EB1
    .word 0xF00F9344,0x8708A3D2,0x1E01F268,0x6906C2FE
    .word 0xF762575D,0x806567CB,0x196C3671,0x6E6B06E7
    .word 0xFED41B76,0x89D32BE0,0x10DA7A5A,0x67DD4ACC
    .word 0xF9B9DF6F,0x8EBEEFF9,0x17B7BE43,0x60B08ED5
    .word 0xD6D6A3E8,0xA1D1937E,0x38D8C2C4,0x4FDFF252
    .word 0xD1BB67F1,0xA6BC5767,0x3FB506DD,0x48B2364B
    .word 0xD80D2BDA,0xAF0A1B4C,0x36034AF6,0x41047A60
    .word 0xDF60EFC3,0xA867DF55,0x316E8EEF,0x4669BE79
    .word 0xCB61B38C,0xBC66831A,0x256FD2A0,0x5268E236
    .word 0xCC0C7795,0xBB0B4703,0x220216B9,0x5505262F
    .word 0xC5BA3BBE,0xB2BD0B28,0x2BB45A92,0x5CB36A04
    .word 0xC2D7FFA7,0xB5D0CF31,0x2CD99E8B,0x5BDEAE1D
    .word 0x9B64C2B0,0xEC63F226,0x756AA39C,0x026D930A
    .word 0x9C0906A9,0xEB0E363F,0x72076785,0x05005713
    .word 0x95BF4A82,0xE2B87A14,0x7BB12BAE,0x0CB61B38
    .word 0x92D28E9B,0xE5D5BE0D,0x7CDCEFB7,0x0BDBDF21
    .word 0x86D3D2D4,0xF1D4E242,0x68DDB3F8,0x1FDA836E
    .word 0x81BE16CD,0xF6B9265B,0x6FB077E1,0x18B74777
    .word 0x88085AE6,0xFF0F6A70,0x66063BCA,0x11010B5C
    .word 0x8F659EFF,0xF862AE69,0x616BFFD3,0x166CCF45
    .word 0xA00AE278,0xD70DD2EE,0x4E048354,0x3903B3C2
    .word 0xA7672661,0xD06016F7,0x4969474D,0x3E6E77DB
    .word 0xAED16A4A,0xD9D65ADC,0x40DF0B66,0x37D83BF0
    .word 0xA9BCAE53,0xDEBB9EC5,0x47B2CF7F,0x30B5FFE9
    .word 0xBDBDF21C,0xCABAC28A,0x53B39330,0x24B4A3A6
    .word 0xBAD03605,0xCDD70693,0x54DE5729,0x23D967BF
    .word 0xB3667A2E,0xC4614AB8,0x5D681B02,0x2A6F2B94
    .word 0xB40BBE37,0xC30C8EA1,0x5A05DF1B,0x2D02EF8D
#endif
#endif

    .section    .text
    .thumb_func
    .globl  Reset_Handler
    .type   Reset_Handler, %function
Reset_Handler:
#if (DFU_BOOTKEY_ADDR != _DISABLE) || (DFU_DBLRESET_MS != _DISABLE)
    ldr     r1, =#_KEY_ADDR
    ldr     r2, =#DFU_BOOTKEY
    movs    r3, #0x00
    ldr     r0, [r1]
    str     r3, [r1]
    cmp     r0, r2
    beq     .L_start_boot
#endif

#if (DFU_DBLRESET_MS != _DISABLE)
/* Storing DFU_BOOTKEY at DFU_BOOTKEY_ADDR and do a delay.
 * In case of RESET at this time bootloader will start from code above. */
    str     r2, [r1]
/* STM32L100 startup clock is about 4.0MHz MSI
 * so, we need T(mS)*2097 ticks to make a required delay */
    ldr     r0, =#(DFU_DBLRESET_MS * 4000 / 3)
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
#endif

#if ( (defined(DFU_VERIFY_CHECKSUM) && (DFU_VERIFY_CHECKSUM != _DISABLE) ) )

    mov     r0, #0xFFFFFFFF
    ldr     r1, =#_APP_START
    ldr     r2, =__romend
    sub     r2, r2, r1
    sub     r2, #8
    bl      .L_crc32

    bne     .L_checksum_valid
    b       .L_start_boot

.L_checksum_valid:

#endif

/* jump to user section */
    ldr     r0, =#_APP_START
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
    ldr     r3, =#RCC_BASE
    mov     r1, #(1 << 28)  /* PWREN */
    str     r1, [r3, #RCC_APB1ENR1]
    ldr     r0, =#PWR_BASE
/* Setting power Range 1 */
    lsrs    r1, #19     /* Range 1 */
    str     r1, [r0, #PWR_CR1]
.L_wait_pw_set:
    ldr     r1, [r0, #PWR_SR2]
    lsrs    r1, #11     /* VOSF -> CF */
    bcs     .L_wait_pw_set
#if defined(STM32L433xx)
/* Disabling Vusb isolation for L433 */
    mov     r1, #(1 << 10)  /* USV */
    str     r1, [r0, #PWR_CR2]
#endif
/* Adjusting flash latency */
    ldr     r0, =#FLASH_R_BASE
    movs    r1, #2
    str     r1, [r0, #FLASH_ACR]
/* Set 48Mhz MSI clock */
    movs    r1, #0xB9
    strb    r1, [r3, #RCC_CR]
/* Set MSI clock as USB clock */
    movs    r1, #0x0C
    strb    r1, [r3, #RCC_CCIPR + 3]
/* Enabling USB pins GPIOA11 GPIO12 AF10*/
    mov     r1, #0x01
    strb    r1, [r3, #RCC_AHB2ENR]
    ldr     r0, =#GPIOA
    ldr     r1, [r0, #GPIO_MODER]
    movs    r2, #0xAA
    bfi     r1, r2, #22, #4
    str     r1, [r0, #GPIO_MODER]
    lsls    r2, #12
    str     r2, [r0, #GPIO_AFRH]
#if (DFU_SEAL_LEVEL != 0)
    ldr     r3, =#seal_flash
    blx     r3
#endif
/* jump to bootloader */
    bl      main

   .thumb_func

#if ( (defined(DFU_VERIFY_CHECKSUM) && (DFU_VERIFY_CHECKSUM != _DISABLE) ) )
#if ( defined(DFU_CHECKSUM_TYPE) && (DFU_CHECKSUM_TYPE==_FAST) )
.L_crc32:
/* R0 <- crc
 * R1 <- buffer
 * R2 <- buffer size
 * R0 -> crc
 */

    push    {r1-r6, lr}

.L_checksum_loop:
    ldrb    r4, [r1]

    eor     r0, r0, r4
    and     r4, r0, #0x000000FF

    ldr     r3, =crc32table
    ldr     r3, [r3, r4, LSL#2]

    lsr     r0, #8
    eor     r0, r3

    add     r1, r1, #1

    eor     r4, r0, #0xFFFFFFFF
    ldr     r5, [r1]
    cmp     r5, r4
    bne     .L_checksum_continue
    ldr     r5, [r1, #4]
    cmp     r5, r0
    bne     .L_checksum_continue

    movs    r0, #1
    pop     {r1-r6, pc}

.L_checksum_continue:
    subs     r2, r2, #1
    bne     .L_checksum_loop
.L_checksum_end:
    movs    r0, #0
    pop     {r1-r6, pc}
#else
.L_crc32:
/* R0 <- crc
 * R1 <- buffer
 * R2 <- buffer size
 * R0 -> 0 = not verified,1 = verified
 */
    push    {r1-r6, lr}

    ldr     r6, =.L_checksum_poly
    ldr     r6, [r6]

.L_checksum_loop:
    ldrb    r3, [r1]
    eor     r0, r0, r3

    mov     r4, 8
.L_bit_loop:
    and     r5, r0, #1
    neg     r5, r5
    mov     r3, r0, LSR#1
    and     r5, r6
    eor     r0, r3, r5

    subs    r4, #1
    bne     .L_bit_loop

    add     r1, r1, #1

    eor     r4, r0, #0xFFFFFFFF
    ldr     r5, [r1]
    cmp     r5, r4
    bne     .L_checksum_continue
    ldr     r5, [r1, #4]
    cmp     r5, r0
    bne     .L_checksum_continue

    movs    r0, #1
    pop     {r1-r6, pc}

.L_checksum_continue:
    subs    r2, r2, #1
    bne     .L_checksum_loop
.L_checksum_end:
    movs    r0, #0
    pop     {r1-r6, pc}

.L_checksum_poly:
    .word   0xEDB88320
#endif
#endif

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
    movs    r4, #0x07
    tst     r4, r0
    bne     Err_unaligned
/* unlocking flash */
    ldr     r3, =#FLASH_R_BASE
.L_flash_unlock:
    ldr     r4, [r3, #FLASH_SR]
    lsls    r4, #16                 /* BSY->CF */
    bcs     .L_flash_unlock
    ldr     r4, =#FLASH_PRGKEY0
    ldr     r5, =#FLASH_PRGKEY1
    str     r4, [r3, #FLASH_KEYR]
    str     r5, [r3, #FLASH_KEYR]
    movs    r6, #0
.L_flash_loop:
/* checking end of block */
    cmp     r6, r2
    bhs     .L_do_verify
/* clean FLASH_SR */
    ldr     r4, [r3, #FLASH_SR]
    str     r4, [r3, #FLASH_SR]
/* check for the page start (2k page)*/
    mov     r4, r6
    adds    r4, r0
    lsls    r5, r4, #21
    bne     .L_do_write
/* erasing page */
/* calculating PNB[7:0] and BKER */
    lsls    r4, #12
    lsrs    r4, #23
    lsls    r4, #3
/* set PER */
    adds    r4, #0x02
    str     r4, [r3, #FLASH_CR]
    movs    r4, #0x01
    strh    r4, [r3, #FLASH_CR + 0x02]  /* set STRT */
    bl      wait_flash_ready
    bne     Err_erase
/* perform doubleword write */
.L_do_write:
    movs    r4, #0x01                   /* set PG */
    str     r4, [r3, #FLASH_CR]
    ldr     r4, [r1, r6]
    str     r4, [r0, r6]
    adds    r6, #0x04
    ldr     r4, [r1, r6]
    str     r4, [r0, r6]
    adds    r6, #0x04
    bl      wait_flash_ready
    bne     Err_prog
    b      .L_flash_loop           /* if no errors */
.L_do_verify:
/* disabling programming */
    movs    r4, #0x00
    str     r4, [r3, #FLASH_CR]
.L_verify_loop:
    subs    r2, #1
    bcc     Err_done
    ldrb    r4, [r0, r2]
    ldrb    r5, [r1, r2]
    cmp     r4, r5
    bne     Err_verify
    b      .L_verify_loop
/* all done */
Err_done:
    movs    r0, #0x00       //OK
    b       .L_exit
Err_unaligned:
    movs    r0, #0x03       // errWRITE (unaligned access)
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
    movs    r4, #0x03
    lsls    r4, #30
    str     r4, [r3, #FLASH_CR] // locking flash
    pop     {r4, r5, r6, pc}
    .size program_flash, . - program_flash


    .thumb_func
    .type   wait_flash_ready, %function
wait_flash_ready:
    ldr     r4, [r3, #FLASH_SR]
    lsls    r4, #16         //BSY->CF
    bcs     wait_flash_ready
    lsrs    r4, #17         //EOP->CF
    bx      lr
    .size wait_flash_ready, . - wait_flash_ready


#if (DFU_SEAL_LEVEL != 0)
    .thumb_func
    .globl seal_flash
    .type seal_flash, %function
seal_flash:
    push    {r4, r5, r6, lr}
    ldr     r3, =#FLASH_R_BASE
    ldrb    r1, [r3, #FLASH_OPTR]
#if (DFU_SEAL_LEVEL == 2)
#warning Protection Level 2 is an irreversible !!
    cmp     r1, #0xCC
    beq     Err_done
    movs    r0, #0xCC
#else
    cmp     r1, #0xAA
    bne     Err_done
    movs    r0, #0x18
#endif
    ldr     r4, =#FLASH_PRGKEY0
    ldr     r5, =#FLASH_PRGKEY1
    str     r4, [r3, #FLASH_KEYR]
    str     r5, [r3, #FLASH_KEYR]
    ldr     r4, =#FLASH_OPTKEY0
    ldr     r5, =#FLASH_OPTKEY1
    str     r4, [r3, #FLASH_OPTKEYR]
    str     r5, [r3, #FLASH_OPTKEYR]
/* clean FLASH_SR */
    ldr     r4, [r3, #FLASH_SR]
    str     r4, [r3, #FLASH_SR]
/* modify OPTR */
    strb    r0, [r3, #FLASH_OPTR]
/* set OPT_STRT */
    movs    r4, #0x02
    strb    r4, [r3, #FLASH_CR + 0x02]
    bl      wait_flash_ready
    bne     Err_prog
    b       Err_done
    .size seal_flash, . - seal_flash
#endif

    .pool
    .end
