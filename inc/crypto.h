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

#ifndef _CRYPTO_H_
#define _CRYPTO_H_
#if defined(__cplusplus)
    extern "C" {
#endif

#if 1

void aes_init(void);
void aes_encrypt(void *out, const void *in, int32_t sz);
void aes_decrypt(void *out, const void *in, int32_t sz);
const char *aes_name;
const uint32_t aes_blksize;

#else

#define DFU_USE_CIPHER





#if (DFU_CIPHER == DFU_CIPHER_RC5_A) && defined(__thumb__)
    #include "rc5_a.h"
    #define DFU_AES_KEY DFU_AES_KEY_A
    #define aes_init(key) _rc5_init()
    #define aes_encrypt(out, in, b) _rc5_encrypt(out, in, b)
    #define aes_decrypt(out, in, b) _rc5_decrypt(out, in, b)

#elif (DFU_CIPHER == DFU_CIPHER_RC5) || (DFU_CIPHER == DFU_CIPHER_RC5_A)
    #include "rc5.h"
    #define aes_init(key) rc5_init()
    #define aes_encrypt(out, in, b) rc5_encrypt(out, in, b)
    #define aes_decrypt(out, in, b) rc5_decrypt(out, in, b)

#elif (DFU_CIPHER == DFU_CIPHER_RAIDEN)
    #include "raiden.h"
    #define aes_init(key) raiden_init()
    #define aes_encrypt(out, in, b) raiden_encrypt(out, in, b)
    #define aes_decrypt(out, in, b) raiden_decrypt(out, in, b)

#elif (DFU_CIPHER == DFU_CIPHER_GOST)
    #include "gost.h"
    #define aes_init(key) gost_init()
    #define aes_encrypt(out, in, b) gost_encrypt(out, in, b)
    #define aes_decrypt(out, in, b) gost_decrypt(out, in, b)

#elif (DFU_CIPHER == DFU_CIPHER_SPECK)
    #include "speck.h"
    #define aes_init(key) speck_init()
    #define aes_encrypt(out, in, b) speck_encrypt(out, in, b)
    #define aes_decrypt(out, in, b) speck_decrypt(out, in, b)

#elif (DFU_CIPHER == DFU_CIPHER_XTEA)
    #include "xtea.h"
    #define aes_init(key) xtea_init()
    #define aes_encrypt(out, in, b) xtea_encrypt(out, in, b)
    #define aes_decrypt(out, in, b) xtea_decrypt(out, in, b)

#elif (DFU_CIPHER == DFU_CIPHER_XTEA1)
    #include "xtea.h"
    #define aes_init(key) xtea_init()
    #define aes_encrypt(out, in, b) xtea_encrypt(out, in, b)
    #define aes_decrypt(out, in, b) xtea_decrypt(out, in, b)

#elif (DFU_CIPHER == DFU_CIPHER_ARC4)
    #include "arc4.h"
    #define aes_init(key) arc4_init()
    #define aes_encrypt(out, in, b) arc4_crypt(out, in, b)
    #define aes_decrypt(out, in, b) arc4_crypt(out, in, b)

#elif (DFU_CIPHER == DFU_CIPHER_CHACHA_A) && defined(__thumb__)
    #include "chacha_a.h"
    #define aes_init(key) _chacha_init()
    #define aes_encrypt(out, in, b) _chacha_crypt(out, in, b)
    #define aes_decrypt(out, in, b) _chacha_crypt(out, in, b)

#elif (DFU_CIPHER == DFU_CIPHER_CHACHA) || (DFU_CIPHER == DFU_CIPHER_CHACHA_A)
    #include "chacha.h"
    #define aes_init(key) chacha_init()
    #define aes_encrypt(out, in, b) chacha_crypt(out, in, b)
    #define aes_decrypt(out, in, b) chacha_crypt(out, in, b)

#elif (DFU_CIPHER == DFU_CIPHER_BLOWFISH)
    #include "blowfish.h"
    #define _aes_init(key) blowfish_init(key)
    #define _aes_encrypt(out, in) blowfish_encrypt(out, in)
    #define _aes_decrypt(out, in) blowfish_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_RTEA)
    #include "rtea.h"
    #define aes_init(key) rtea_init()
    #define aes_encrypt(out, in, b) rtea_encrypt(out, in, b)
    #define aes_decrypt(out, in, b) rtea_decrypt(out, in, b)

#else
    #undef DFU_USE_CIPHER
    #define CRYPTO_BLKSIZE 1
    #define CRYPTO_NAME "No encryption"
    #define aes_init(...)
    #define aes_encrypt(...)
    #define aes_decrypt(...)
#endif


#include "misc.h"

static uint8_t IV[CRYPTO_BLKSIZE] __attribute__((aligned(4)));
static const uint8_t key[32] = {DFU_AES_KEY_A, DFU_AES_KEY_B};
static const uint32_t ck[2] = {DFU_AES_NONCE0, DFU_AES_NONCE1};

static aes_init(void) {
    memcpy(IV, ck, CRYPTO_BLKSIZE);
    _aes_init(key);
}

static encrypt_block(void *out, const void *in) {
    uint8_t S[CRYPTO_BLKSIZE] __attribute__((aligned(4)));
    memcpy(&S, in, CRYPTO_BLKSIZE);
    memxor(&S, &IV, CRYPTO_BLKSIZE);
    _aes_encrypt(&S, &IV);
    memcpy(out, &IV, CRYPTO_BLKSIZE);
}

static void decrypt_block(void *out, const void *in) {
    uint8_t S[CRYPTO_BLKSIZE] __attribute__((aligned(4)));
    memcpy(&S, in, CRYPTO_BLKSIZE);
    _aes_decrypt(&S, &S);
    memxor(&S, &IV, CRYPTO_BLKSIZE);
    memcpy(&IV, in, CRYPTO_BLKSIZE);
    memcpy(out, &S, CRYPTO_BLKSIZE);
}

static void aes_encrypt(void *out, const void *in, int32_t sz) {
    while(sz > 0) {
        encrypt_block(out, in);
        out += CRYPTO_BLKSIZE;
        in += CRYPTO_BLKSIZE;
        sz -= CRYPTO_BLKSIZE;
    }
}

static void aes_decrypt(void *out, const void *in, int32_t sz) {
    while(sz > 0) {
        decrypt_block(out, in);
        out += CRYPTO_BLKSIZE;
        in += CRYPTO_BLKSIZE;
        sz -= CRYPTO_BLKSIZE;
    }
}


#endif


#if defined(__cplusplus)
    }
#endif
#endif //_CRYPTO_H_
