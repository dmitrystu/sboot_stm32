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

#include <stdint.h>
#include <string.h>
#include "misc.h"
#include "rc5.h"

#define rounds      12
#define c           4
#define t           2 * (rounds + 1)

#define Pw          0xb7e15163
#define Qw          0x9e3779b9

static uint32_t rc5_keys[t];

void rc5_encrypt (uint32_t *out, const uint32_t *in) {
    uint32_t A = in[0] + rc5_keys[0];
    uint32_t B = in[1] + rc5_keys[1];
    for (int i = 1; i <= rounds; i++) {
        A = __rol32((A ^ B), B) + rc5_keys[2 * i];
        B = __rol32((B ^ A), A) + rc5_keys[2 * i + 1];
    }
    out[0] = A;
    out[1] = B;
}

void rc5_decrypt (uint32_t *out, const uint32_t *in) {
    uint32_t A = in[0];
    uint32_t B = in[1];
    for (int i = rounds; i > 0; i--) {
        B = __ror32((B - rc5_keys[2 * i + 1]), A) ^ A;
        A = __ror32((A - rc5_keys[2 * i]), B) ^ B;
    }
    out[0] = A - rc5_keys[0];
    out[1] = B - rc5_keys[1];
}

void rc5_init (const void* key) {
    uint32_t L[4];
    memcpy(L, key, 16);
    rc5_keys[0] = Pw;
    for (int i = 1; i < t; i++){
        rc5_keys[i] = rc5_keys[i-1] + Qw;
    }
    for (uint32_t A = 0, B = 0, i = 0, j = 0, k = 3 * t; k > 0; k--) {
        A = rc5_keys[i] = __rol32(rc5_keys[i] + A + B, 3);
        B = L[j] = __rol32(L[j] + A + B, (A + B));
        if (++i == t) i = 0;
        if (++j == c) j = 0;
    }
}
