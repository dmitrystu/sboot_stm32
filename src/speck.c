/* This file is the part of the STM32 secure bootloader
 *
 * SPECK 64/128-CBC block cipher implementation based on
 * "The Simon and Speck Families Of Lightwieght Block Ciphers"
 * http://eprint.iacr.org/2013/404.pdf
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

#include <stdint.h>
#include "rot.h"
#include "../config.h"

#define ROUNDS  27

static uint32_t roundkey[ROUNDS];
static uint32_t CK[2];

inline static void speck_round(uint32_t *a, uint32_t *b, const uint32_t key) {
    *a = key ^ (__ror(*a, 8) + *b);
    *b = *a ^ __rol(*b, 3);
}

inline static void speck_back(uint32_t *a, uint32_t *b, const uint32_t key) {
    *b = __ror(*b ^ *a, 3);
    *a = __rol((key ^ *a) - *b, 8);
}

inline static void __memcpy(void *dst, const void *src, uint32_t sz) {
    while(sz--) {
        *(uint8_t*)dst++ = *(uint8_t*)src++;
    };
}

static void speck_encrypt_block(uint32_t *dst, const uint32_t *src) {
    uint32_t A = src[0] ^ CK[0];
    uint32_t B = src[1] ^ CK[1];
    for (int i = 0; i < ROUNDS; i++) {
        speck_round(&B, &A, roundkey[i]);
    }
    CK[0] = dst[0] = A;
    CK[1] = dst[1] = B;
}

static void speck_decrypt_block(uint32_t *dst, const uint32_t *src) {
    uint32_t A = src[0];
    uint32_t B = src[1];
    for (int i = ROUNDS-1; i >= 0; i--) {
        speck_back(&B, &A, roundkey[i]);
    }
    A ^= CK[0]; CK[0] = src[0]; dst[0] = A;
    B ^= CK[1]; CK[1] = src[1]; dst[1] = B;
}


void speck_init(const uint8_t *key) {
    uint32_t K[4];
    __memcpy(K, key, 16);
    for (int i = 0, j = 0 ; i < ROUNDS; i++) {
        roundkey[i] = K[0];
        if (++j > 3) j = 1;
        speck_round(&K[j], &K[0], i);
    }
    CK[0] = DFU_AES_NONCE0;
    CK[1] = DFU_AES_NONCE1;
}

void speck_encrypt(uint32_t *out, const uint32_t *in, int32_t bytes) {
    while (bytes > 0) {
        speck_encrypt_block(out, in);
        out += 2;
        in += 2;
        bytes -=8;
    }
}

void speck_decrypt(uint32_t *out, const uint32_t *in, int32_t bytes) {
    while (bytes > 0) {
        speck_decrypt_block(out, in);
        out += 2;
        in += 2;
        bytes -= 0x08;
    }
}
