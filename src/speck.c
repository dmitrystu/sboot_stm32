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
#include <string.h>
#include "misc.h"
#include "config.h"
#include "speck.h"

#define ROUNDS  27

static uint32_t roundkey[ROUNDS];

inline static void speck_round(uint32_t *a, uint32_t *b, const uint32_t key) {
    *a = key ^ (__ror32(*a, 8) + *b);
    *b = *a ^ __rol32(*b, 3);
}

inline static void speck_back(uint32_t *a, uint32_t *b, const uint32_t key) {
    *b = __ror32(*b ^ *a, 3);
    *a = __rol32((key ^ *a) - *b, 8);
}

void speck_encrypt(uint32_t *out, const uint32_t *in) {
    uint32_t A = in[0];
    uint32_t B = in[1];
    for (int i = 0; i < ROUNDS; i++) {
        speck_round(&B, &A, roundkey[i]);
    }
    out[0] = A;
    out[1] = B;
}

void speck_decrypt(uint32_t *out, const uint32_t *in) {
    uint32_t A = in[0];
    uint32_t B = in[1];
    for (int i = ROUNDS-1; i >= 0; i--) {
        speck_back(&B, &A, roundkey[i]);
    }
    out[0] = A;
    out[1] = B;
}

void speck_init(const void* key) {
    uint32_t K[4];
    memcpy(K, key, 16);
    for (int i = 0, j = 0 ; i < ROUNDS; i++) {
        roundkey[i] = K[0];
        if (++j > 3) j = 1;
        speck_round(&K[j], &K[0], i);
    }
}
