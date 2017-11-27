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
#include "misc.h"
#include "config.h"
#include "xtea.h"

#define rounds  32
#define delta   0x9E3779B9

#if defined(DFU_CIPHER_XTEA1)
    #define RA(x, s, k) ((x << 4) ^ (x >> 5)) + ( x ^ s) + __rol32(k[s & 0x03], x)
    #define RB(x, s, k) ((x << 4) ^ (x >> 5)) + ( x ^ s) + __rol32(k[(s >> 11) & 0x03], x)
#else
    #define RA(x, s, k) (((x << 4) ^ (x >> 5)) +  x) ^ (s + k[s & 0x03])
    #define RB(x, s, k) (((x << 4) ^ (x >> 5)) +  x) ^ (s + k[(s >> 11) & 0x03])
#endif

static const uint8_t key[] = {DFU_AES_KEY_A};

static uint32_t K[4];
static uint32_t CK[2];

static void xtea_encrypt_block(uint32_t *out, const uint32_t *in) {
    uint32_t A = in[0] ^ CK[0];
    uint32_t B = in[1] ^ CK[1];
    uint32_t S = 0;
    for (int i = 0; i < rounds; i++) {
       A += RA(B, S, K);
       S += delta;
       B += RB(A, S, K);
    }
    out[0] = CK[0] = A;
    out[1] = CK[1] = B;
}

static void xtea_decrypt_block(uint32_t *out, const uint32_t *in) {
    uint32_t A = in[0];
    uint32_t B = in[1];
    uint32_t S = rounds * delta;
    for (int i = 0; i < rounds;  i++) {
       B -= RB(A, S, K);
       S -= delta;
       A -= RA(B, S, K);
    }
    A ^= CK[0]; CK[0] = in[0]; out[0] = A;
    B ^= CK[1]; CK[1] = in[1]; out[1] = B;
}

void xtea_init(void) {
    __memcpy(K, key, sizeof(K));
    CK[0] = DFU_AES_NONCE0;
    CK[1] = DFU_AES_NONCE1;
}

void xtea_encrypt(uint32_t *out, const uint32_t *in, int32_t bytes) {
    while(bytes > 0) {
        xtea_encrypt_block(out, in);
        in += 2;
        out += 2;
        bytes -= 0x08;
    }
}

void xtea_decrypt(uint32_t *out, const uint32_t *in, int32_t bytes) {
    while(bytes > 0) {
        xtea_decrypt_block(out, in);
        in += 2;
        out += 2;
        bytes -= 0x08;
    }
}
