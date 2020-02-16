/* This file is the part of the STM32 secure bootloader
 *
 * RC6-32/20/16 block cipher implementation based on
 * RonaldL.Rivest ,M.J.B.Robshaw ,R.Sidney ,andY.L.Yin "The RC6(TM) Block Cipher"
 * http://people.csail.mit.edu/rivest/pubs/RRSY98.pdf
 *
 * Copyright ©2020 Dmitry Filimonchuk <dmitrystu[at]gmail[dot]com>
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
#include "rc6.h"

#define ROUNDS      20
#define KW          4
#define SW          2 * (ROUNDS + 2)
#define LOGW        5

#define Pw          0xb7e15163
#define Qw          0x9e3779b9

static uint32_t RK[SW];

void rc6_encrypt (uint32_t *out, const uint32_t *in) {
    uint32_t A = in[0];
    uint32_t B = in[1] + RK[0];
    uint32_t C = in[2];
    uint32_t D = in[3] + RK[1];
    for (int i = 2; i <= 2 * ROUNDS; i += 2) {
        uint32_t t, u;
        t = __rol32(B * (B + B + 1), LOGW);
        u = __rol32(D * (D + D + 1), LOGW);
        A = __rol32((A ^ t), u) + RK[i];
        C = __rol32((C ^ u), t) + RK[i + 1];
        t = A;
        A = B;
        B = C;
        C = D;
        D = t;
    }
    out[0] = A + RK[2 * ROUNDS + 2];
    out[1] = B;
    out[2] = C + RK[2 * ROUNDS + 3];
    out[3] = D;
}

void rc6_decrypt (uint32_t *out, const uint32_t *in) {
    uint32_t A = in[0] - RK[2 * ROUNDS + 2];
    uint32_t B = in[1];
    uint32_t C = in[2] - RK[2 * ROUNDS + 3];
    uint32_t D = in[3];
    for (int i = 2 * ROUNDS; i > 0; i -= 2) {
        uint32_t t, u;
        t = D;
        D = C;
        C = B;
        B = A;
        A = t;
        u = __rol32(D * (D + D + 1), LOGW);
        t = __rol32(B * (B + B + 1), LOGW);
        C = __ror32((C - RK[i + 1]), t) ^ u;
        A = __ror32((A - RK[i]), u) ^ t;
    }
    out[0] = A;
    out[1] = B - RK[0];
    out[2] = C;
    out[3] = D - RK[1];
}

void rc6_init (const void* key) {
    uint32_t L[KW];
    memcpy(L, key, sizeof(L));
    RK[0] = Pw;
    for (int i = 1; i < SW; i++){
        RK[i] = RK[i-1] + Qw;
    }
    for (uint32_t A = 0, B = 0, i = 0, j = 0, k = 3 * SW; k > 0; k--) {
        A = RK[i] = __rol32(RK[i] + A + B, 3);
        B = L[j] = __rol32(L[j] + A + B, (A + B));
        if (++i == SW) i = 0;
        if (++j == KW) j = 0;
    }
}
