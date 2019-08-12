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
#include "misc.h"
#include "config.h"
#include "rtea.h"

#define rounds  64

static const uint8_t key[]  = {DFU_AES_KEY_A, DFU_AES_KEY_B};
static uint32_t K[8];
static uint32_t CK[2];

static void rtea_encrypt_block(uint32_t *out, const uint32_t *in) {
    uint32_t A = in[0] ^ CK[0];
    uint32_t B = in[1] ^ CK[1];
    for (int32_t i = 0; i < rounds; i++) {
        B += A + ((A << 6) ^ (A >> 8)) + K[i & 0x07] + i;
        i++;
        A += B + ((B << 6) ^ (B >> 8)) + K[i & 0x07] + i;
    }
    out[0] = CK[0] = A;
    out[1] = CK[1] = B;
}

static void rtea_decrypt_block(uint32_t *out, const uint32_t *in) {
    uint32_t A = in[0];
    uint32_t B = in[1];
    for (int32_t i = (rounds - 1); i >= 0; i--) {
        A -= B + ((B << 6) ^ (B >> 8)) + K[i & 0x07] + i;
        i--;
        B -= A + ((A << 6) ^ (A >> 8)) + K[i & 0x07] + i;
    }

    A ^= CK[0]; CK[0] = in[0]; out[0] = A;
    B ^= CK[1]; CK[1] = in[1]; out[1] = B;
}

void rtea_init(void) {
    __memcpy(K, key, sizeof(K));
    CK[0] = DFU_AES_NONCE0;
    CK[1] = DFU_AES_NONCE1;
}

void rtea_encrypt(uint32_t *out, const uint32_t *in, int32_t bytes) {
    while(bytes > 0) {
        rtea_encrypt_block(out, in);
        in += 2;
        out += 2;
        bytes -= 0x08;
    }
}

void rtea_decrypt(uint32_t *out, const uint32_t *in, int32_t bytes) {
    while(bytes > 0) {
        rtea_decrypt_block(out, in);
        in += 2;
        out += 2;
        bytes -= 0x08;
    }
}
