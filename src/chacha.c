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
#include "../config.h"
#include "rot.h"

#define QR(s,a,b,c,d) Qround((s), (a) << 24 | (b) << 16 | (c) << 8 | (d) << 0)



inline static void __memcpy(void *dst, const void *src, uint32_t sz) {
    while(sz--) {
        *(uint8_t*)dst++ = *(uint8_t*)src++;
    };
}




static uint32_t inits[16];
static uint32_t state[16];


static void Qround (uint32_t *s, uint32_t abcd) {

    uint32_t A = s[(abcd >> 24) & 0x0F];
    uint32_t B = s[(abcd >> 16) & 0x0F];
    uint32_t C = s[(abcd >> 8 ) & 0x0F];
    uint32_t D = s[(abcd >> 0 ) & 0x0F];

    A += B; D ^= A; D = __ror(D, 32 - 16);
    C += D; B ^= C; B = __ror(B, 32 - 12);
    A += B; D ^= A; D = __ror(D, 32 - 8);
    C += D; B ^= C; B = __ror(B, 32 - 7);

    s[(abcd >> 24) & 0x0F] = A;
    s[(abcd >> 16) & 0x0F] = B;
    s[(abcd >> 8)  & 0x0F] = C;
    s[(abcd >> 0)  & 0x0F] = D;
}

static void chacha_block() {
    __memcpy(state, inits, sizeof(state));
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
}

void chacha_init(const uint8_t *key) {
    /* set constants */
    inits[0] = 0x61707865;
    inits[1] = 0x3320646e;
    inits[2] = 0x79622d32;
    inits[3] = 0x6b206574;
    /* set key */
    __memcpy(&inits[4], key, 0x40);
    /* set counter */
    inits[12] = 0x00;
     /* set nonse */
    inits[13] = DFU_AES_NONCE0;
    inits[14] = DFU_AES_NONCE1;
    inits[15] = DFU_ASE_NONCE2;
}



void chacha_crypt(uint32_t *out, const uint32_t *in, int32_t bytes) {
    while (bytes > 0) {
        inits[12]++;
        chacha_block();
        for (int i = 0; i < 16; i++) {
            *out++ = (state[i] + inits[i]) ^ *in++;
        }
        bytes -= 64;
    }
}
