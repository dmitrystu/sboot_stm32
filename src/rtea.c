/* This file is the part of the STM32 secure bootloader
 *
 * Ruptor's TEA or Repaired TEA
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
#include "rtea.h"

#define rounds  64

static uint32_t K[8];

void rtea_encrypt(uint32_t *out, const uint32_t *in) {
    uint32_t A = in[0];
    uint32_t B = in[1];
    for (int32_t i = 0; i < rounds; i++) {
        B += A + ((A << 6) ^ (A >> 8)) + K[i & 0x07] + i;
        i++;
        A += B + ((B << 6) ^ (B >> 8)) + K[i & 0x07] + i;
    }
    out[0] = A;
    out[1] = B;
}

void rtea_decrypt(uint32_t *out, const uint32_t *in) {
    uint32_t A = in[0];
    uint32_t B = in[1];
    for (int32_t i = (rounds - 1); i >= 0; i--) {
        A -= B + ((B << 6) ^ (B >> 8)) + K[i & 0x07] + i;
        i--;
        B -= A + ((A << 6) ^ (A >> 8)) + K[i & 0x07] + i;
    }

    out[0] = A;
    out[1] = B;
}

void rtea_init(const void* key) {
    memcpy(K, key, sizeof(K));
}
