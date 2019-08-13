/* This file is the part of the STM32 secure bootloader
 *
 * Copyright 2019 by Tsien (UK) Ltd.
 *
 * Author: Adrian Carpenter <tech[at]tsien[dot]com>
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
 *
 */

#include "config.h"

    .syntax unified
#if defined(__ARM_ARCH_7EM__)
    .cpu cortex-m4
#elif defined(__ARM_ARCH_6M__)
    .cpu cortex-m0plus
#else
#error checksum_crc32.S unsupported architecture
#endif
    .thumb

#if ( (defined(DFU_VERIFY_CHECKSUM) && (DFU_VERIFY_CHECKSUM != _DISABLE) ) )
#if ( defined(DFU_VERIFY_CHECKSUM) && (DFU_VERIFY_CHECKSUM==CRC32FAST) )
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
#endif /* ( defined(DFU_VERIFY_CHECKSUM) && (DFU_VERIFY_CHECKSUM==CRC32FAST) ) */

   .thumb_func
   .globl .L_validate_checksum

#if defined(__ARM_ARCH_7EM__)
#if ( defined(DFU_VERIFY_CHECKSUM) && (DFU_VERIFY_CHECKSUM==CRC32FAST) )
.L_validate_checksum:
/* R1 <- buffer
 * R2 <- buffer size
 * R0 -> 1 = validated, 0 = invalid
 */
    push    {r1-r6, lr}

    mov     r0, #0xFFFFFFFF

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
#endif /* ( defined(DFU_VERIFY_CHECKSUM) && (DFU_VERIFY_CHECKSUM==CRC32FAST) ) */

#if ( defined(DFU_VERIFY_CHECKSUM) && (DFU_VERIFY_CHECKSUM==CRC32SMALL) )

.L_validate_checksum:
/* R1 <- buffer
 * R2 <- buffer size
 * R0 -> 1 = validated, 0 = invalid
 */
    push    {r1-r6, lr}

    mov     r0, #0xFFFFFFFF

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
#endif /* ( defined(DFU_VERIFY_CHECKSUM) && (DFU_VERIFY_CHECKSUM==CRC32SMALL) ) */
#endif /* defined(__ARM_ARCH_7EM__) */

#if defined(__ARM_ARCH_6M__)
#if ( (defined(DFU_VERIFY_CHECKSUM) && (DFU_VERIFY_CHECKSUM != _DISABLE) ) )
#if ( defined(DFU_VERIFY_CHECKSUM) && (DFU_VERIFY_CHECKSUM==CRC32FAST) )
.L_validate_checksum:
/* R1 <- buffer
 * R2 <- buffer size
 * R0 -> 1 = validated, 0 = invalid
 */
    push    {r1-r6, lr}

    movs    r0, #0
    subs    r0, #1

.L_checksum_loop:
    ldrb    r4, [r1]

    eors    r0, r0, r4
    movs    r4, 0xFF
    ands    r4, r0, r4

    ldr     r3, =crc32table
    lsls    r4, #2
    adds    r4, r3
    ldr     r3, [r4]

    lsrs    r0, #8
    eors    r0, r3

    adds    r1, r1, #1

    movs    r4, #0
    subs    r4, #1
    eors    r4, r4, r0
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
#endif /* ( defined(DFU_VERIFY_CHECKSUM) && (DFU_CHECKSUM_TYPE==CRC32FAST) ) */

#if ( defined(DFU_VERIFY_CHECKSUM) && (DFU_VERIFY_CHECKSUM==CRC32SMALL) )
.L_validate_checksum:
/* R1 <- buffer
 * R2 <- buffer size
 * R0 -> 1 = validated, 0 = invalid
 */
    push    {r1-r6, lr}

    movs    r0, #0
    subs    r0, #1

    ldr     r6, =.L_checksum_poly
    ldr     r6, [r6]

.L_checksum_loop:
    ldrb    r3, [r1]
    eors    r0, r0, r3

    movs    r4, 8
.L_bit_loop:
    movs    r5, #1
    ands    r5, r0, r5
    mvns    r5, r5
    movs    r3, r0, LSR#1
    ands    r5, r6
    eors    r3, r3, r5
    movs    r0, r3

    subs    r4, #1
    bne     .L_bit_loop

    adds    r1, r1, #1

    movs    r4, #0
    subs    r4, #1
    eors    r4, r4, r0
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
#endif /*( defined(DFU_VERIFY_CHECKSUM) && (DFU_VERIFY_CHECKSUM==CRC32SMALL) ) */
#endif /* ( (defined(DFU_VERIFY_CHECKSUM) && (DFU_VERIFY_CHECKSUM != _DISABLE) ) ) */
#endif /* defined(__ARM_ARCH_6EM__) */

#endif /* ( (defined(DFU_VERIFY_CHECKSUM) && (DFU_VERIFY_CHECKSUM != _DISABLE) ) ) */
