/* This file is the part of the STM32 secure bootloader
 *
 * Rijndael AES-128/192/256
 *
 * Copyright ©2020 Dmitry Filimonchuk <dmitrystu[at]gmail[dot]com>
 * Based on: https://github.com/kokke/tiny-AES-c
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
#include "rijndael.h"
#include "misc.h"

#if (RIJNDAEL_KEYSIZE == 128)
    #define ROUNDS  10  // The number of rounds in AES Cipher.
#elif (RIJNDAEL_KEYSIZE == 192)
    #define ROUNDS  12
#elif (RIJNDAEL_KEYSIZE == 256)
    #define ROUNDS  14
#else
    #error "Unsupported AES key size"
#endif

#define KEYSIZE     (RIJNDAEL_KEYSIZE / 8)
#define KEYSIZE32   (RIJNDAEL_KEYSIZE / 32)
#define RKSIZE32    (4 * (ROUNDS + 1))

// state - array holding the intermediate results during decryption.
typedef uint8_t state_t[4][4];

// Roundkey storage
static uint32_t roundkey[RKSIZE32];

// Basic GF2 math
static uint8_t gmul2(uint8_t x) {
    if (x & 0x80) {
        return (x << 1) ^ 0x1B;
    } else {
        return (x << 1);
    }
}

#define gmul4(x) gmul2(gmul2(x))
#define gmul8(x) gmul2(gmul4(x))

#if (RIJNDAEL_ROM_SBOXES == 1)

static const uint8_t sbox[256] = {
    //0     1    2      3     4    5     6     7      8    9     A      B    C     D     E     F
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
};

static const uint8_t rbox[256] = {
    0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
    0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
    0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
    0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
    0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
    0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
    0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
    0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
    0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
    0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
    0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
    0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
    0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
    0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
    0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
    0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d
};

static void init_sbox(void) { }

#else //USE_ROM_SBOXES

static uint8_t sbox[256];
static uint8_t rbox[256];

static void init_sbox(void) {
    uint32_t p = 1, q = 1;
    /* loop invariant: p * q == 1 in the Galois field */
    do {
        /* multiply p by 3 */
        p ^= gmul2(p);
        /* divide q by 3 (equals multiplication by 0xf6) */
        q ^= (q << 1);
        q ^= (q << 2);
        q ^= (q << 4);
        q &= 0xFF;
        if (q & 0x80) {
            q ^= 0x09;
        }
        /* compute the affine transformation */
        uint32_t s = 0x63 ^ q ^ (q << 1) ^ (q << 2) ^ (q << 3) ^ (q << 4);
        s = 0xFF & (s ^ (s >> 8));

        sbox[p] = (uint8_t)s;
        rbox[s] = (uint8_t)p;
    } while (p != 1);

    /* 0 is a special case since it has no inverse */
    sbox[0x00] = 0x63;
    rbox[0x63] = 0x00;
}

#endif //USE_ROM_SBOXES

static void sub_box(void *data, const uint8_t *box, size_t sz) {
    uint8_t *raw = data;
    for (size_t i = 0; i < sz; i++) {
        uint8_t x = raw[i];
        raw[i] = box[x];
    }
}

static void AddRoundKey(void *dst, const void *src, int round) {
    uint8_t *rk = (uint8_t*)roundkey + sizeof(state_t) * round;
    for (int i = 0; i < sizeof(state_t); i++) {
        ((uint8_t*)dst)[i] = ((uint8_t*)src)[i] ^ rk[i];
    }
}

static void SubBytes(state_t* state) {
    sub_box(state, sbox, sizeof(state_t));
}

static void ShiftRows(state_t* state)
{
  uint8_t temp;
  // Rotate first row 1 columns to left
  temp           = (*state)[0][1];
  (*state)[0][1] = (*state)[1][1];
  (*state)[1][1] = (*state)[2][1];
  (*state)[2][1] = (*state)[3][1];
  (*state)[3][1] = temp;

  // Rotate second row 2 columns to left
  temp           = (*state)[0][2];
  (*state)[0][2] = (*state)[2][2];
  (*state)[2][2] = temp;

  temp           = (*state)[1][2];
  (*state)[1][2] = (*state)[3][2];
  (*state)[3][2] = temp;

  // Rotate third row 3 columns to left
  temp           = (*state)[0][3];
  (*state)[0][3] = (*state)[3][3];
  (*state)[3][3] = (*state)[2][3];
  (*state)[2][3] = (*state)[1][3];
  (*state)[1][3] = temp;
}

static void MixColumns(state_t* state) {
    uint8_t Tmp, Tm, t;
    for (int i = 0; i < 4; ++i) {
        t   = (*state)[i][0];
        Tmp = (*state)[i][0] ^ (*state)[i][1] ^ (*state)[i][2] ^ (*state)[i][3] ;
        Tm  = (*state)[i][0] ^ (*state)[i][1] ; Tm = gmul2(Tm);  (*state)[i][0] ^= Tm ^ Tmp ;
        Tm  = (*state)[i][1] ^ (*state)[i][2] ; Tm = gmul2(Tm);  (*state)[i][1] ^= Tm ^ Tmp ;
        Tm  = (*state)[i][2] ^ (*state)[i][3] ; Tm = gmul2(Tm);  (*state)[i][2] ^= Tm ^ Tmp ;
        Tm  = (*state)[i][3] ^ t ;              Tm = gmul2(Tm);  (*state)[i][3] ^= Tm ^ Tmp ;
    }
}

// Let "*" denotes polynomial multiplication modulo x4+1 over GF(2^8)
// Let "+" denotes polynomyal addition over GF(2^8) (XOR) X + X = 0
// A' = (A*8 + A*4 + A*2) + (B*8 + B*2 + B) + (C*8 + C*4 + C) + (D*8 + D)
// B' = (A*8 + A) + (B*8 + B*4 + B*2) + (C*8 + C*2 + C) + (D*8 + D*4 + D)
// C' = (A*8 + A*4 + A) + (B*8 + B) + (C*8 + C*4 + C*2) + (D*8 + D*2 + D)
// D' = (A*8 + A*2 + A) + (B*8 + B*4 + B) + (C*8 + C) + (D*8 + D*4 + D*2)
// Let
// T = (A + B + C + D)*8 + (A + B + C + D)
// Then
// A' = T + (A + C)*4 + (A + B)*2 + A
// B' = T + (B + D)*4 + (B + C)*2 + B
// C' = T + (C + A)*4 + (C + D)*2 + C
// D' = T + (D + B)*4 + (D + A)*2 + D
// So (A + C)*4 = (C + A)* 4 and (B + D)*4 = (D + B)*4
static void InvMixColumns(state_t* state) {
    for (int i = 0; i < 4; ++i) {
        uint8_t a = (*state)[i][0];
        uint8_t b = (*state)[i][1];
        uint8_t c = (*state)[i][2];
        uint8_t d = (*state)[i][3];
        uint8_t T, X;
        T = a ^ b ^ c ^ d;
        T ^= gmul8(T);
        X = gmul4(a ^ c);
        (*state)[i][0] = T ^ X ^ gmul2(a ^ b) ^ a;
        (*state)[i][2] = T ^ X ^ gmul2(c ^ d) ^ c;
        X = gmul4(b ^ d);
        (*state)[i][1] = T ^ X ^ gmul2(b ^ c) ^ b;
        (*state)[i][3] = T ^ X ^ gmul2(d ^ a) ^ d;
    }
}

static void InvSubBytes(state_t* state) {
    sub_box(state, rbox, sizeof(state_t));
}

static void InvShiftRows(state_t* state)
{
  uint8_t temp;

  // Rotate first row 1 columns to right
  temp = (*state)[3][1];
  (*state)[3][1] = (*state)[2][1];
  (*state)[2][1] = (*state)[1][1];
  (*state)[1][1] = (*state)[0][1];
  (*state)[0][1] = temp;

  // Rotate second row 2 columns to right
  temp = (*state)[0][2];
  (*state)[0][2] = (*state)[2][2];
  (*state)[2][2] = temp;

  temp = (*state)[1][2];
  (*state)[1][2] = (*state)[3][2];
  (*state)[3][2] = temp;

  // Rotate third row 3 columns to right
  temp = (*state)[0][3];
  (*state)[0][3] = (*state)[1][3];
  (*state)[1][3] = (*state)[2][3];
  (*state)[2][3] = (*state)[3][3];
  (*state)[3][3] = temp;
}

void rijndael_init(const void *key) {
    uint8_t rcon = 0x01;
    init_sbox();
    memcpy(roundkey, key, KEYSIZE);
    for (int i = KEYSIZE32, j = 0; i < RKSIZE32; i++) {
        uint32_t temp = roundkey[i - 1];
        if (j == 0) {
            temp = __ror32(temp, 8);
            sub_box(&temp, sbox, 4);
            temp ^= rcon;
            rcon = gmul2(rcon);
        }
        // 256-bit key special
        if (KEYSIZE == 32 && j == 4) {
            sub_box(&temp, sbox, 4);
        }
        if (++j == KEYSIZE32) {
            j = 0;
        }
        roundkey[i] = temp ^ roundkey[i - KEYSIZE32];
    }
}

void rijndael_encrypt(uint32_t *out, const uint32_t *in) {
    state_t state;
    int round = 0;
    // Add the First round key to the state before starting the rounds.
    AddRoundKey(&state, in, round);
    for(;;) {
        round++;
        SubBytes(&state);
        ShiftRows(&state);
        if (round == ROUNDS) {
            break;
        }
        MixColumns(&state);
        AddRoundKey(&state, &state, round);
    }
    AddRoundKey(out, &state, round);
}

void rijndael_decrypt(uint32_t *out, const uint32_t *in) {
    state_t state;
    int round = ROUNDS;
    AddRoundKey(&state, in, round);
    for(;;) {
        round--;
        InvShiftRows(&state);
        InvSubBytes(&state);
        if (round == 0) {
            break;
        }
        AddRoundKey(&state, &state, round);
        InvMixColumns(&state);
    }
    AddRoundKey(out, &state, round);
}
