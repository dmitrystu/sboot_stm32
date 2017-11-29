/* This file is the part of the STM32 secure bootloader
 *
 * ChaCha20 stream cipher implementation based on RFC7539
 * "ChaCha20 and Poly1305 for IETF Protocols"
 * https://tools.ietf.org/html/rfc7539
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
#define QR(a,b,c,d) (((a) << 24) | ((b) << 16) | ((c) << 8) | (d))



    .syntax unified
    .cpu cortex-m0plus
    .thumb
    .section .text


    .thumb_func
    .globl _chacha_init
    .type _chacha_init, %function
/* R0 <- key pointer */
_chacha_init:
    adr     r0, _initial
    ldr     r1, =_inits
    movs    r3, 0x3F
.L_copy_key:
    ldrb    r2, [r0, r3]
    strb    r2, [r1, r3]
    subs    r3, 0x01
    bhs     .L_copy_key
    bx      lr
    .size _chacha_init, . - _chacha_init

    .thumb_func
    .globl  _chacha_crypt
    .type _chacha_crypt, %function
/* R0 <- out pointer
 * R1 <- in pointer
 * R2 <- block size
 */
_chacha_crypt:
    push    {r4, r5, r6, r7, lr}
    cmp     r2, #0x00
    ble     .L_exit
/* processing block */
    ldr     r4, =_inits
.L_next_state:
/* increment counter in init block*/
    ldr     r3, [r4, #0x30]
    adds    r3, #0x01
    str     r3, [r4, #0x30]
/* copy init to state */
    ldr     r5, =_state
    movs    r6, #0x3C
.L_copy_state:
    ldr     r3, [r4, r6]
    str     r3, [r5, r6]
    subs    r6, #0x04
    bhs     .L_copy_state
    movs    r6, #10
    ldr     r3, =_Qround
.L_qrounds:
    ldr     r7, =#QR(0, 4,  8, 12)
    blx     r3
    ldr     r7, =#QR(1, 5,  9, 13)
    blx     r3
    ldr     r7, =#QR(2, 6, 10, 14)
    blx     r3
    ldr     r7, =#QR(3, 7, 11, 15)
    blx     r3
    ldr     r7, =#QR(0, 5, 10, 15)
    blx     r3
    ldr     r7, =#QR(1, 6, 11, 12)
    blx     r3
    ldr     r7, =#QR(2, 7,  8, 13)
    blx     r3
    ldr     r7, =#QR(3, 4,  9, 14)
    blx     r3
    subs    r6, #0x01
    bne     .L_qrounds
.L_add_init:
    ldr     r3, [r4, r6]
    ldr     r7, [r5, r6]
    add     r7, r3
    ldr     r3, [r1]
    eors    r3, r7
    str     r3, [r0]
    adds    r0, #0x04
    adds    r1, #0x04
    subs    r2, #0x04
    ble     .L_exit
    adds    r6, #0x04
    cmp     r6, #0x40
    bne     .L_add_init
    b       .L_next_state
.L_exit:
    pop     {r4, r5, r6, r7, pc}
    .size  _chacha_crypt, . - _chacha_crypt

/* R
 * R5 <- state
 */

 #define A r0
 #define B r1
 #define C r2
 #define D r4
 #define T r3
    .thumb_func
    .type _Qround, %function
_Qround:
    push    {r0-r4, lr}

    mov     T, r7
    lsrs    T, #22
    ldr     A, [r5, r3]
    lsls    T, r7, #8
    lsrs    T, #22
    ldr     B, [r5, r3]
    lsls    T, r7, #16
    lsrs    T, #22
    ldr     C, [r5, r3]
    lsls    T, r7, #24
    lsrs    T, #22
    ldr     D, [r5, r3]

    add     A, B          //A += B
    eors    D, A          //D ^= A
    movs    T, #(32 - 16)
    rors    D, T          //D <<<= 15
    add     C, D
    eors    B, C
    movs    T, #(32 - 12)
    rors    B, T
    add     A, B
    eors    D, A
    movs    T, #(32 - 8)
    rors    D, T
    add     C, D
    eors    B, C
    movs    T, #(32 - 7)
    rors    B, T

    mov     T, r7
    lsrs    T, #22
    str     A, [r5, r3]
    lsls    T, r7, #8
    lsrs    T, #22
    str     B, [r5, r3]
    lsls    T, r7, #16
    lsrs    T, #22
    str     C, [r5, r3]
    lsls    T, r7, #24
    lsrs    T, #22
    str     D, [r5, r3]

    pop     {r0-r4, pc}

    .size _Qround, . - _Qround

_initial:
    .long   0x61707865, 0x3320646e, 0x79622d32, 0x6b206574
    .byte   DFU_AES_KEY_A, DFU_AES_KEY_B
    .long   0x00
    .long   DFU_AES_NONCE0, DFU_AES_NONCE1, DFU_AES_NONCE2

    .pool



    .section .bss
    .align 2
_inits:     .space 64
_state:     .space 64
