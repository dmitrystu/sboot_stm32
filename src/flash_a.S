/* This file is the part of the STM32 secure bootloader
 *
 * Copyright ©2016 Dmitry Filimonchuk <dmitrystu[at]gmail[dot]com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *   http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "../config.h"
#include "memmap.h"

#if ((DFU_BLOCKSZ % (FLASH_PAGESZ / 2)) != 0)
    #error DFU Transfer size must be divisible to MCU halfpage size. Adjust DFU_BLOCKSZ
#endif

#define HP_MASK ((FLASH_PAGESZ / 2) - 1)


    .syntax unified
    .cpu cortex-m0plus
    .fpu softvfp
    .thumb


/* using RAM for this functions */

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
    movs    r4, #HP_MASK
    tst     r4, r0
    bne     Err_unaligned
/* adjust block size to halfpage */
    adds    r5, r4, #0x01
    subs    r5, r2
    ands    r5, r4
    adds    r2, r5
/* unlock program enable */
    bl      unlock_pe
/* unlocking program memoty */
    ldr     r4, =#FLASH_PRGKEY0
    ldr     r5, =#FLASH_PRGKEY1
    str     r4, [r3, #FLASH_PRGKEYR]
    str     r5, [r3, #FLASH_PRGKEYR]
.L_w_unlock_prg:
    ldr     r4, [r3, #FLASH_PECR]
    lsrs    r4, #0x02
    bcs     .L_w_unlock_prg
/* flash loop */
.L_flash_loop:
/* checking if page erase required */
    movs    r4, #HP_MASK
    lsls    r4, #0x01
    ands    r4, r0
    bne     .L_write_halfpage
/* do page erase */
    movs    r4, #0x41
    lsls    r4, #0x03       //ERASE | PROG
    str     r4, [r3, #FLASH_PECR]
    movs    r4, #0x00
    str     r4, [r0]        //fake write to rom to start erase
    bl      .L_wait_prog_done
    bcc     Err_erase
.L_write_halfpage:
    movs    r4, #0x81
    lsls    r4, #0x03       // FPRG | PROG
    str     r4, [r3, #FLASH_PECR]
/* wait BSY */
.L_w_bsy:
    ldr     r4, [r3, #FLASH_SR]
    lsrs    r4, #0x01       //BSY->CF
    bcs     .L_w_bsy
    movs    r5, #0x00
/* do halfpage write */
.L_hp_loop:
    ldr     r4, [r1, r5]
    str     r4, [r0, r5]
    adds    r5, #0x04
    cmp     r5, #HP_MASK
    blo     .L_hp_loop
    bl      .L_wait_prog_done
    bcc     Err_prog
    movs    r4, #0x00
    str     r4, [r3, #FLASH_PECR]
/* do hp verify */
.L_verify_loop:
    ldr     r4, [r0]
    ldr     r5, [r1]
    cmp     r4, r5
    bne     Err_verify
    adds    r0, #0x04
    adds    r1, #0x04
    subs    r2, #0x04
    movs    r4, #HP_MASK
    ands    r4, r2
    bne     .L_verify_loop
/* checking for done */
    cmp     r2, #0x00
    bne     .L_flash_loop
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
    movs    r4, #0x07
    str     r4, [r3, #FLASH_PECR] // locking flash
    pop     {r4, r5, pc}

/* wait for programming done */
/* return CF=0 if program failed */
.L_wait_prog_done:
    ldr     r4, [r3, #FLASH_SR]
    lsrs    r4, #0x01               //BSY -> CF
    bcs     .L_wait_prog_done       //wait BSY low
    lsrs    r4, #0x02               //ENDHV -> CF
    bcc     .L_wait_prog_done       //wait ENDHV high
    ldr     r4, [r3, #FLASH_SR]     //reload FLASH_SR
    lsrs    r4, #0x02               //EOP -> CF
    //bcc     .L_wpd_exit
    movs    r4, #0x02               //clear EOP
    str     r4, [r3, #FLASH_SR]
.L_wpd_exit:
    bx      lr

/* unlock program enable function and set R3 to FLASH_R_BASE */
unlock_pe:
    ldr     r3, =#FLASH_R_BASE
    ldr     r4, =#FLASH_PEKEY0
    ldr     r5, =#FLASH_PEKEY1
    str     r4, [r3, #FLASH_PEKEYR]
    str     r5, [r3, #FLASH_PEKEYR]
.L_w_unlock_pe:
    ldr     r4, [r3, #FLASH_PECR]
    lsrs    r4, #0x01
    bcs     .L_w_unlock_pe
    bx      lr


    .size program_flash, . - program_flash

#ifdef DFU_INTF_EEPROM
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
/* flash unlocked. let's do write */
    movs    r4, #0x22
    lsls    r4, #0x03   // FIX | DATA
    str     r4, [r3, #FLASH_PECR]
/* writing byte by byte */
.L_ee_write:
    ldrb    r4, [r1]
    strb    r4, [r0]
    ldrb    r5, [r0]
    cmp     r5, r4
    bne     Err_verify
    adds    r0, #0x01
    adds    r1, #0x01
    subs    r2, #0x01
    bne     .L_ee_write
    b       Err_done

    .size   program_eeprom, . - program_eeprom
#endif






    .pool

    .end
