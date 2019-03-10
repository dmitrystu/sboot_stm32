/* This file is the part of the STM32 secure bootloader
 *
 * Blowfish cypher implementation based on
 * https://www.schneier.com/academic/archives/1994/09/description_of_a_new.html
 *
 *  Xorshift implementation based on Xorshift RNGs by George Marsaglia
 * https://www.jstatsoft.org/article/view/v008i14/xorshift.pdf
 *
 * Copyright ©2017 Dmitry Filimonchuk <dmitrystu[at]gmail[dot]com>
 * *
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
#include "blowfish.h"

#define rounds  16

static const union {
    uint32_t    key32[8];
    uint8_t     key8[32];
} key = {.key8 = {DFU_AES_KEY_A, DFU_AES_KEY_B}};

static struct {
    uint32_t P[18];
    uint32_t S[4][256];
} D;

static uint32_t CK[2];

static uint32_t F(uint32_t x) {
    uint32_t h = D.S[0][x >> 24] + D.S[1][(x >> 16) & 0xFF];
    return (h ^ D.S[2][(x >> 8) & 0xFF]) + D.S[3][x & 0xFF];
}

static void encrypt(uint32_t *A, uint32_t *B){
    uint32_t L = *A;
    uint32_t R = *B;
    for (int i = 0; i < rounds; i+=2) {
        L ^= D.P[i];
        R ^= F(L);
        R ^= D.P[i+1];
        L ^= F(R);
    }
    L ^= D.P[16];
    R ^= D.P[17];
    *A = R;
    *B = L;
}

static void decrypt(uint32_t *A, uint32_t *B) {
    uint32_t L = *A;
    uint32_t R = *B;
    for (int i = rounds; i > 0; i-=2) {
        L ^= D.P[i+1];
        R ^= F(L);
        R ^= D.P[i];
        L ^= F(R);
    }
    L ^= D.P[1];
    R ^= D.P[0];
    *A = R;
    *B = L;
}

void blowfish_init(void) {
    uint32_t L = 0;
    uint32_t R = 0;
/* Original implementation is based on PI digits, but
 * "There is nothing sacred about pi; any string of random bits--digits
 * of e, RAND tables, output of a random number generator--will suffice.
 *  B. Schneier"
 * So, we will use pseudo random numbers fom xorshift
 */
    uint32_t S = 0xDEADBEEF;
    uint32_t *K = (uint32_t*)&D;
    for (int i = 0; i < sizeof(D) / 4; i++) {
        S ^= S << 13;
        S ^= S >> 17;
        S ^= S << 5;
        K[i] = S;
    }

    for (int i = 0; i < 18; i++) {
        D.P[i] ^= key.key32[i & 0x07];
    }

    for (int i = 0; i < 18; i+=2) {
        encrypt(&L, &R);
        D.P[i] = L;
        D.P[i+1] = R;
    }
    for (int i = 0; i < 4; ++i) {
        for (int j = 0; j < 256; j+=2) {
            encrypt(&L, &R);
            D.S[i][j] = L;
            D.S[i][j+1] = R;
        }
    }
    CK[0] = DFU_AES_NONCE0;
    CK[1] = DFU_AES_NONCE1;
}


static void blowfish_encrypt_block(uint32_t *out, const uint32_t *in) {
    uint32_t A = in[0] ^ CK[0];
    uint32_t B = in[1] ^ CK[1];
    encrypt(&A, &B);
    out[0] = CK[0] = A;
    out[1] = CK[1] = B;
}

static void blowfish_decrypt_block(uint32_t *out, const uint32_t *in) {
    uint32_t A = in[0];
    uint32_t B = in[1];
    decrypt(&A, &B);
    A ^= CK[0]; CK[0] = in[0]; out[0] = A;
    B ^= CK[1]; CK[1] = in[1]; out[1] = B;
}


void blowfish_encrypt(uint32_t *out, const uint32_t *in, int32_t bytes) {
    while(bytes > 0) {
        blowfish_encrypt_block(out, in);
        in += 2;
        out += 2;
        bytes -= 0x08;
    }
}

void blowfish_decrypt(uint32_t *out, const uint32_t *in, int32_t bytes) {
    while(bytes > 0) {
        blowfish_decrypt_block(out, in);
        in += 2;
        out += 2;
        bytes -= 0x08;
    }
}
