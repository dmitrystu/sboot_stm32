/* This file is the part of the STM32 secure bootloader
 *
 * RC6-32/20/16 block cipher implementation based on
 * RonaldL.Rivest ,M.J.B.Robshaw ,R.Sidney ,andY.L.Yin "The RC6(TM) Block Cipher"
 * http://people.csail.mit.edu/rivest/pubs/RRSY98.pdf
 *
 * Copyright ©2020 Dmitry Filimonchuk <dmitrystu[at]gmail[dot]com>
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

#define ROUNDS  20
#define T       2 * (ROUNDS + 2)
#define C       4
#define PW      0xB7E15163
#define QW      0x9E3779B9

    .syntax unified
    .cpu cortex-m0plus
    .thumb

    .section .text.rc6a_init
    .globl rc6a_init
    .thumb_func
    .type rc6a_init, %function
/* R0 <- key array
 */
rc6a_init:
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
    ldr     r0, =rc6_subkeys
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
    .size rc6a_init, . - rc6a_init
    .pool


/* R0 <- destination pointer
 * R1 <- source pointer
 */
    .section .text.rc6a_encrypt
    .globl rc6a_encrypt
    .type rc6a_encrypt, %function
    .thumb_func
rc6a_encrypt:
    push    {r4-r7, lr}
    // A->R2, B->R3, C->R4, D->R5
    ldmia   r1!, {r2,r3,r4,r5}
    ldr     r1, =rc6_subkeys
    // B = B + S[0]
    ldmia   r1!,{r6,r7}
    adds    r3, r6
    // D = D + S[1]
    adds    r5, r7
    movs    r6, #ROUNDS
.L_enc_round:
    push    {r0, r1}
    // R0 t = (B*(2B + 1)) <<< 5
    movs    r7, #27
    adds    r0, r3, r3
    adds    r0, #1
    muls    r0, r3
    rors    r0, r7
    // R1 u = (D*(2D + 1)) <<< 5
    adds    r1, r5, r5
    adds    r1, #1
    muls    r1, r5
    rors    r1, r7
    // A = ((A ^ t) <<< u)
    eors    r2, r0
    rsbs    r7, r1, #0
    rors    r2, r7
    // C = ((C ^ u) <<< t)
    eors    r4, r1
    rsbs    r7, r0, #0
    rors    r4, r7
    pop     {r0, r1}
    // A = A + SK[2i]
    ldmia    r1!, {r7}
    adds    r2, r7
    // C = C + S[2i+1]
    ldmia    r1!, {r7}
    adds    r4, r7
    //(A,B,C,D) = (B,C,D,A)
    movs    r7, r2
    movs    r2, r3
    movs    r3, r4
    movs    r4, r5
    movs    r5, r7
    subs    r6, #0x01
    bne     .L_enc_round
    // A = A + S[2R + 2]   C = C + S[2R + 3]
    ldmia   r1!, {r6,r7}
    add     r2, r6
    add     r4, r7
    //store outputs
    stmia   r0!, {r2-r5}
    pop     {r4-r7, pc}
    .size rc6a_encrypt, . - rc6a_encrypt
    .pool

    .section .text.rc6a_decrypt
    .globl rc6a_decrypt
    .type rc6a_decrypt, %function
    .thumb_func
rc6a_decrypt:
    push    {r4-r7, lr}
    // A->R2, B->R3, C->R4, D->R5
    ldmia   r1!, {r2,r3,r4,r5}
    ldr     r1, =(rc6_subkeys + 8 * ROUNDS)
    // A = A - S[2R + 2]
    ldr     r7, [r1, #0x08]
    subs    r2, r7
    // C = C - S[2R + 2]
    ldr     r7, [r1, #0x0C]
    subs    r4, r7
    movs    r6, #ROUNDS
.L_dec_round:
//    subs    r1, #0x08
    //(A,B,C,D) = (D,A,B,C)
    movs    r7, r5
    movs    r5, r4
    movs    r4, r3
    movs    r3, r2
    movs    r2, r7
    // A = A - S[2i]
    ldr     r7, [r1, #0x00]
    subs    r2, r7
    // C = C - S[2i+1]
    ldr     r7, [r1, #0x04]
    subs    r4, r7
    push    {r0, r1}
    // R0 t = (B*(2B + 1)) <<< 5
    movs    r7, #27
    adds    r0, r3, r3
    adds    r0, 1
    muls    r0, r3
    rors    r0, r7
    // R1 u = (D*(2D + 1)) <<< 5
    adds    r1, r5, r5
    adds    r1, 1
    muls    r1, r5
    rors    r1, r7
    // A = (A >>> u) ^ t
    rors    r2, r1
    eors    r2, r0
    // C = (C >> t) ^ u
    rors    r4, r0
    eors    r4, r1
    pop     {r0, r1}
    subs    r1, #0x08
    subs    r6, #0x01
    bne     .L_dec_round
    ldmia   r1!,{r6,r7}
    // B = B + S[0]
    subs    r3, r6
    // D = D + S[1]
    subs    r5, r7

    stmia   r0!, {r2-r5}
    pop     {r4-r7, pc}
    .size rc6a_decrypt, . - rc6a_decrypt
    .pool

    .section .bss
    .align 2
rc6_subkeys:
    .space  (T * 4)
    .size rc6_subkeys, . - rc6_subkeys
    .end
