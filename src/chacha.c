/* This file is the part of the STM32 secure bootloader
 *
 * ChaCha20 stream cipher implementation based on RFC7539
 * "ChaCha20 and Poly1305 for IETF Protocols"
 * https://tools.ietf.org/html/rfc7539
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
#include "chacha.h"

#define QR(s,a,b,c,d) Qround((s), (a) << 24 | (b) << 16 | (c) << 8 | (d) << 0)

#define SPLIT(x) (x) & 0xFF, ((x) >> 8) & 0xFF, ((x) >> 16) & 0xFF, ((x) >> 24) & 0xFF

static const uint8_t prefix[] = {
    0x65, 0x78, 0x70, 0x61, 0x6e, 0x64, 0x20, 0x33,
    0x32, 0x2d, 0x62, 0x79, 0x74, 0x65, 0x20, 0x6b,
};

static uint32_t inits[16];
static uint32_t state[16];
static uint8_t  bytecount;

static void Qround (uint32_t *s, uint32_t abcd) {

    uint32_t A = s[(abcd >> 24) & 0x0F];
    uint32_t B = s[(abcd >> 16) & 0x0F];
    uint32_t C = s[(abcd >> 8 ) & 0x0F];
    uint32_t D = s[(abcd >> 0 ) & 0x0F];

    A += B; D ^= A; D = __rol32(D, 16);
    C += D; B ^= C; B = __rol32(B, 12);
    A += B; D ^= A; D = __rol32(D, 8);
    C += D; B ^= C; B = __rol32(B, 7);

    s[(abcd >> 24) & 0x0F] = A;
    s[(abcd >> 16) & 0x0F] = B;
    s[(abcd >> 8)  & 0x0F] = C;
    s[(abcd >> 0)  & 0x0F] = D;
}

static void chacha_block() {
    memcpy(state, inits, sizeof(state));
    for (int i = 0; i < 10; i++) {
        QR(state, 0, 4,  8, 12);
        QR(state, 1, 5,  9, 13);
        QR(state, 2, 6, 10, 14);
        QR(state, 3, 7, 11, 15);
        QR(state, 0, 5, 10, 15);
        QR(state, 1, 6, 11, 12);
        QR(state, 2, 7,  8, 13);
        QR(state, 3, 4,  9, 14);
    }
    for (int i = 0; i < 16; i++) {
        state[i] += inits[i];
    }
}

void chacha_init(const void* key, const void* nonce) {
    memcpy(&inits[0], prefix, 16);
    memcpy(&inits[4], key, 32);
    memcpy(&inits[13], nonce, 12);
    inits[12] = 0;
    bytecount = 0;
}

void chacha_crypt(void *out, const void *in) {
    if ((bytecount & 0x3F) == 0) {
        inits[12]++;
        chacha_block();
    }
    *(uint8_t*)out = *(uint8_t*)in ^ ((uint8_t*)state)[bytecount & 0x3F];
    bytecount++;
}
