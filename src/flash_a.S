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


#define FLASH_R_BASE    0x40022000
#define PEKEYR0         0x89ABCDEF
#define PEKEYR1         0x02030405
#define PRGKEYR0        0x8C9DAEBF
#define PRGKEYR1        0x13141516


#define PECR            0x04
#define PEKEYR          0x0C
#define PRGKEYR         0x10
#define SR              0x18



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
    ldr     r3, =#FLASH_R_BASE
/* checking halfpage alignment */
    movs    r4, #0x3F
    ands    r4, r0
    bne    Err_unaligned
/* adjust block size to halfpage */
    movs    r4, #0x40
    movs    r5, #0x3F
    subs    r4, r2
    ands    r4, r5
    adds    r2, r4
/* unlock program enable */
    ldr     r4, =#PEKEYR0
    ldr     r5, =#PEKEYR1
    str     r4, [r3, #PEKEYR]
    str     r5, [r3, #PEKEYR]
.L_w_unlock_pe:
    ldr     r4, [r3, #0x04]
    lsrs    r4, #0x01
    bcs     .L_w_unlock_pe
/* unlocking program memoty */
    ldr     r4, =#PRGKEYR0
    ldr     r5, =#PRGKEYR1
    str     r4, [r3, #PRGKEYR]
    str     r5, [r3, #PRGKEYR]
.L_w_unlock_prg:
    ldr     r4, [r3, #PECR]
    lsrs    r4, #0x02
    bcs     .L_w_unlock_prg
/* flash loop */
.L_flash_loop:
/* checking if page erase required */
    movs    r4, #0x7F
    ands    r4, r0
    bne     .L_write_halfpage
/* do page erase */
    movs    r4, #0x41
    lsls    r4, #0x03       //ERASE | PROG
    str     r4, [r3, #PECR]
    str     r4, [r0]        //fake write to rom to start erase
.L_w_erase_done:
    ldr     r4, [r3, #SR]  //FLASH->SR
    lsrs    r4, #0x01       //BSY->CF
    bcs     .L_w_erase_done
/* check EOP */
    lsrs    r4, #0x01
    bcc     Err_erase
/* clear EOP */
    movs    r4, #0x02
    str     r4, [r3, #SR]
/* prepare halfpage write */
.L_write_halfpage:
    movs    r4, #0x81
    lsls    r4, #0x03       // FPRG | PROG
    str     r4, [r3, #PECR]
    movs    r5, #0x00
/* do halfpage write */
.L_hp_loop:
    ldr     r4, [r1, r5]
    str     r4, [r0, r5]
    adds    r5, #0x04
    cmp     r5, #0x40
    bne     .L_hp_loop
.L_w_prog_done:
    ldr     r4, [r3, #SR]
    lsrs    r4, #0x01
    bcs     .L_w_prog_done
/* checking EOP */
    lsrs    r4, #0x01
    bcc     Err_prog
/* clearing EOP */
    movs    r4, 0x02
    str     r4, [r3, #SR]
    movs    r4, #0x00
    str     r4, [r3, #PECR]
/* do hp verify */
.L_verify_loop:
    ldr     r4, [r0]
    ldr     r5, [r1]
    cmp     r4, r5
    bne     Err_verify
    adds    r0, #0x04
    adds    r1, #0x04
    subs    r2, #0x04
    movs    r4, #0x3F
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
    str     r4, [r3, #PECR] // locking flash
    pop     {r4, r5, pc}
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
    ldr     r3, =#FLASH_R_BASE
/* unlock program enable */
    ldr     r4, =#PEKEYR0
    ldr     r5, =#PEKEYR1
    str     r4, [r3, #PEKEYR]
    str     r5, [r3, #PEKEYR]
.L_wait_unlock:
    ldr     r4, [r3, #PECR]
    lsrs    r4, #0x01
    bcs     .L_wait_unlock
/* flash unlocked. let's do write */
    movs    r4, #0x22
    lsls    r4, #0x03   // FIX | DATA
    str     r4, [r0, #PECR]
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
