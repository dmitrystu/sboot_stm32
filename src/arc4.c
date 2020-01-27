/* This file is the part of the STM32 secure bootloader
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
#include "arc4.h"

static uint8_t S[256];
static uint8_t si;
static uint8_t sj;

void arc4_init (const void *key) {
    for (int i=0; i < 256; i++) {
        S[i] = i;
    }
    for (int i=0, j=0; i < 255; i++) {
        j = (j + S[i] + ((uint8_t*)key)[i & 0x0F]) & 0xFF;
        uint8_t _t = S[i];
        S[i] = S[j];
        S[j] = _t;
    }
    si = 0;
    sj = 0;
}

void arc4_crypt(void *out, const void *in) {
    uint8_t _t;
    _t = S[++si];
    sj = sj + _t;
    S[si] = S[sj];
    S[sj] = _t;
    *(uint8_t*)out = *(uint8_t*)in ^ S[(S[si] + S[sj]) & 0xFF];
}

