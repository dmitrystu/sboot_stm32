/* This file is the part of the STM32 secure bootloader
 *
 * RC5-32/12/128-CBC block cipher implementation based on
 * Ronald L. Rivest "The RC5 Encryption Algorithm"
 * http://people.csail.mit.edu/rivest/Rivest-rc5rev.pdf
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

//#include "config.h"

#define R       12
#define T       2 * (R + 1)
#define C       4
#define PW      0xB7E15163
#define QW      0x9E3779B9

    .syntax unified
    .cpu cortex-m0plus
    .thumb
    .section .text

    .globl _rc5_init
    .thumb_func
    .type _rc5_init, %function
/* R0 <- key array
 */
_rc5_init:
    push    {r4,r5,r6,r7, lr}
    sub     sp, #0x14
    mov     r2, sp
/* copy key to L */
    movs    r1, #0x10
.L_copy_key:
    subs    r1, #0x01
    ldrb    r3, [r0, r1]
    strb    r3, [r2, r1]
    bne     .L_copy_key
/* R2 <- L[0] */
/* prepare S. Fill keyset */
    ldr     r0, =_rc5_keyset
    ldr     r1, =#PW
    ldr     r3, =#QW
    movs    r4, #0x00
.L_fill_keyset:
    str     r1, [r0, r4]
    add     r1, r3
    adds    r4, #0x04
    cmp     r4, #(T * 4)
    bne     .L_fill_keyset
/* mixing keyset */
/* R0 = S[0] */
/* R2 = L[0] */
/* R1 = counter */
/* R3 = A */
/* R4 = B */
/* R5 = TEMP */
/* R6 = i */
/* R7 = j */
    movs    r1, #(T * 3)
    movs    r3, #0x00
    movs    r4, #0x00
    movs    r6, #0x00
    movs    r7, #0x00
.L_mix_keys:
    ldr     r5, [r0, r6]
    add     r3, r3, r4      //R3 <- A + B
    add     r3, r5          //R3 <- S[i] + A + B
    movs    r5, #29
    rors    r3, r5          //R3 <- (S[i] + A + B) <<< 3
    str     r3, [r0, r6]    //A' -> S[i]
    adds    r5, r4, r3      //R5 <- (A' + B)
    ldr     r4, [r2, r7]
    add     r4, r5          //R4 <- L[j] + A' + B
    rsbs    r5, r5, #0      //R5 <- 0 - (A' + B)
    rors    r4, r5          //R4 <- (L[j] + A' + B) <<< (A' + B)
    str     r4, [r2, r7]    //L[j] <- B'
    ldr     r3, [r0, r6]    //restore A'
    adds    r6, #0x04
    cmp     r6, #(T * 4)
    bne     .L_chk_c
    movs    r6, #0x00
.L_chk_c:
    adds    r7, #0x04
    cmp     r7, #(C * 4)
    bne     .L_chk_counter
    movs    r7, #0x00
.L_chk_counter:
    subs    r1, #0x01
    bne     .L_mix_keys
    add     sp, #0x14
    pop     {r4, r5, r6, r7, pc}
    .size _rc5_init, . - _rc5_init



/* R0 <- destination pointer
 * R1 <- source pointer
 * R2 <- unused
 * R3 = A
 * R4 = B
 * R5 = S[]
 * R6 = rounds
 * R7 = TEMP
 */
    .globl _rc5_encrypt
    .type _rc5_encrypt, %function
    .thumb_func
_rc5_encrypt:
    push    {r4, r5, r6, r7, lr}
    ldr     r3, [r1]            //A
    ldr     r4, [r1, #0x04]     //B
/* start RC5 block */
    ldr     r5, =_rc5_keyset
    ldr     r7, [r5]
    add     r3, r7              //A + S[0]
    ldr     r7, [r5, #0x04]
    add     r4, r7              //B + S[1]
    movs    r6, #0x08
.L_enc_roundloop:
    eors    r3, r4              //A ^ B
    rsbs    r7, r4, #0x00
    rors    r3, r7              // (A ^ B) >>> B
    ldr     r7, [r5, r6]        //R7 <- S[2*i]
    add     r3, r7              // A' = ((A ^ B) <<< B) + S[2*i]
    eors    r4, r3              // B ^ A'
    rsbs    r7, r3, #0x00
    rors    r4, r7              // (B ^ A') >>> A'
    adds    r6, #0x04
    ldr     r7, [r5, r6]        //R7 <- S[2 * i + 1]
    add     r4, r7              // B' = ((B ^ A') <<< A') + S[2*i +1]
    adds    r6, #0x04
    cmp     r6, #(T * 4)
    bne     .L_enc_roundloop
/* store encrypted */
    str     r3, [r0]
    str     r4, [r0, #0x04]
    pop     {r4, r5, r6, r7, pc}
    .size _rc5_encrypt, . - _rc5_encrypt


    .globl _rc5_decrypt
    .type _rc5_decrypt, %function
    .thumb_func
_rc5_decrypt:
    push    {r4, r5, r6, r7, lr}
    ldr     r5, =_rc5_keyset
    ldr     r3, [r1]            //A
    ldr     r4, [r1, #0x04]     //B
    movs    r6, #(T * 4 - 4)
.L_dec_roundloop:
    ldr     r7, [r5, r6]        //R7 <- S[2*i - 1]
    subs    r4, r7              //R4 <- B - S[2*i + 1]
    rors    r4, r3              //R4 <- (B - S[2*i +1]) >>> A
    eors    r4, r3              //R4 <- B' = ((B - S[2*i +1]) >>> A) ^ A
    subs    r6, #0x04
    ldr     r7, [r5, r6]        //R7 <- S[2*i]
    subs    r3, r7              //R3 <- (A - S[2*i])
    rors    r3, r4              //R3 <- (A - S[2*i]) >>> B')
    eors    r3, r4              //R3 <- A' = (A - S[2*i]) >>> B') ^ B'
    subs    r6, #0x04
    cmp     r6, #0x04
    bne     .L_dec_roundloop
    ldr     r7, [r5, #0x04]
    subs    r4, r7
    ldr     r7, [r5, #0x00]
    subs    r3, r7
    str     r3, [r0, #0x00]
    str     r4, [r0, #0x04]
    pop     {r4, r5, r6, r7, pc}
    .size _rc5_decrypt, . - _rc5_decrypt

    .pool

    .section .bss
    .align 3
_rc5_keyset:
    .space  (T * 4)

    .end
