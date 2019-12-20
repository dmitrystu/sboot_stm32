/* This file is the part of the STM32 secure bootloader
 *
 * eXtended TEA CBC block cipher based on:
 * "Tea extensions" Roger M. Needham and David J. Wheeler
 * http://www.cix.co.uk/~klockstone/xtea.pdf
 * "Extended TEA Algorithms" Tom St Denis
 * http://tomstdenis.tripod.com/xtea.pdf
 *
 * Copyright ©2017 Dmitry Filimonchuk <dmitrystu[at]gmail[dot]com>
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
#include "xtea.h"

#define rounds  32
#define delta   0x9E3779B9

#define RA(x, s, k) ((x << 4) ^ (x >> 5)) + ( x ^ s) + __rol32(k[s & 0x03], x)
#define RB(x, s, k) ((x << 4) ^ (x >> 5)) + ( x ^ s) + __rol32(k[(s >> 11) & 0x03], x)

static uint32_t K[4];

void xtea1_encrypt(uint32_t *out, const uint32_t *in) {
    uint32_t A = in[0];
    uint32_t B = in[1];
    uint32_t S = 0;
    for (int i = 0; i < rounds; i++) {
       A += RA(B, S, K);
       S += delta;
       B += RB(A, S, K);
    }
    out[0] = A;
    out[1] = B;
}

void xtea1_decrypt(uint32_t *out, const uint32_t *in) {
    uint32_t A = in[0];
    uint32_t B = in[1];
    uint32_t S = rounds * delta;
    for (int i = 0; i < rounds;  i++) {
       B -= RB(A, S, K);
       S -= delta;
       A -= RA(B, S, K);
    }
    out[0] = A;
    out[1] = B;
}

void xtea1_init(const void* key) {
    memcpy(K, key, sizeof(K));
}
