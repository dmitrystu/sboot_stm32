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
/* R0 <- key pointer
 * R1 <- iv pointer
 */
_chacha_init:
    push    {r4, r5, lr}
    ldr     r2, =_inits
    adr     r3, _preamble
    movs    r4, #0x10
    bl      .L_memcpy
    adds    r2, #0x10
    mov     r3, r0
    movs    r4, #0x20
    bl      .L_memcpy
    adds    r2, #0x20
    stmia   r2!, {r4}
    mov     r3, r1
    movs    r4, 0x0C
    bl      .L_memcpy
    ldr     r2, =_counter
    str     r4, [r2]
    pop     {r4, r5, pc}
.L_memcpy:
    subs    r4, #1
    ldrb    r5, [r3, r4]
    strb    r5, [r2, r4]
    bne     .L_memcpy
    bx      lr
    .size _chacha_init, . - _chacha_init

    .thumb_func
    .globl  _chacha_crypt
    .type _chacha_crypt, %function
/* R0 <- out pointer
 * R1 <- in pointer
 */
_chacha_crypt:
    push    {r4, r5, r6, r7, lr}
    ble     .L_exit
/* processing block */
    ldr     r5, =_state
    ldr     r3, =_counter
    ldr     r3, [r3]
    ands    r3, r3
    bne     .L_process_byte
/* processing new state */
    ldr     r4, =_inits
.L_next_state:
/* increment counter in init block*/
    ldr     r3, [r4, #0x30]
    adds    r3, #0x01
    str     r3, [r4, #0x30]
/* copy init to state */
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
    str     r7, [r5, r6]
    adds    r6, #0x04
    cmp     r6, #0x40
    bne     .L_add_init
    movs    r3, #0x00
.L_process_byte:
    ldrb    r2, [r5, r3]
    ldrb    r4, [r1]
    eors    r4, r2
    strb    r4, [r0]
    movs    r4, #0x3F
    adds    r3, #0x01
    ands    r3, r4
    ldr     r2, =_counter
    str     r3, [r2]
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

    .align 2
_preamble:
    .byte   0x65, 0x78, 0x70, 0x61, 0x6e, 0x64, 0x20, 0x33
    .byte   0x32, 0x2d, 0x62, 0x79, 0x74, 0x65, 0x20, 0x6b

    .pool

    .section .bss
    .align 2
_counter:   .space 4
_inits:     .space 64
_state:     .space 64
