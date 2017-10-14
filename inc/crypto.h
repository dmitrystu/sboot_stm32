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


#define DFU_USE_CIPHER

#if defined(DFU_CIPHER_RC5_A) && defined(__thumb__)
    #include "rc5_a.h"
    #define DFU_AES_KEY DFU_AES_KEY_A
    #define aes_init(key) _rc5_init(key)
    #define aes_encrypt(out, in, b) _rc5_encrypt(out, in, b)
    #define aes_decrypt(out, in, b) _rc5_decrypt(out, in, b)

#elif defined(DFU_CIPHER_RC5) || defined(DFU_CIPHER_RC5_A)
    #include "rc5.h"
    #define DFU_AES_KEY DFU_AES_KEY_A
    #define aes_init(key) rc5_init(key)
    #define aes_encrypt(out, in, b) rc5_encrypt(out, in, b)
    #define aes_decrypt(out, in, b) rc5_decrypt(out, in, b)

#elif defined(DFU_CIPHER_RAIDEN)
    #include "raiden.h"
    #define DFU_AES_KEY DFU_AES_KEY_A
    #define aes_init(key) raiden_init(key)
    #define aes_encrypt(out, in, b) raiden_encrypt(out, in, b)
    #define aes_decrypt(out, in, b) raiden_decrypt(out, in, b)

#elif defined(DFU_CIPHER_GOST)
    #include "gost.h"
    #define DFU_AES_KEY DFU_AES_KEY_A DFU_AES_KEY_B
    #define aes_init(key) gost_init(key)
    #define aes_encrypt(out, in, b) gost_encrypt(out, in, b)
    #define aes_decrypt(out, in, b) gost_decrypt(out, in, b)

#elif defined(DFU_CIPHER_SPECK)
    #include "speck.h"
    #define DFU_AES_KEY DFU_AES_KEY_A
    #define aes_init(key) speck_init(key)
    #define aes_encrypt(out, in, b) speck_encrypt(out, in, b)
    #define aes_decrypt(out, in, b) speck_decrypt(out, in, b)

#elif defined(DFU_CIPHER_XTEA)
    #include "xtea.h"
    #define DFU_AES_KEY DFU_AES_KEY_A
    #define aes_init(key) xtea_init(key)
    #define aes_encrypt(out, in, b) xtea_encrypt(out, in, b)
    #define aes_decrypt(out, in, b) xtea_decrypt(out, in, b)

#elif defined(DFU_CIPHER_XTEA1)
    #include "xtea.h"
    #define DFU_AES_KEY DFU_AES_KEY_A
    #define aes_init(key) xtea_init(key)
    #define aes_encrypt(out, in, b) xtea_encrypt(out, in, b)
    #define aes_decrypt(out, in, b) xtea_decrypt(out, in, b)

#elif defined(DFU_CIPHER_ARC4)
    #include "arc4.h"
    #define DFU_AES_KEY DFU_AES_KEY_A
    #define aes_init(key) arc4_init(key)
    #define aes_encrypt(out, in, b) arc4_crypt(out, in, b)
    #define aes_decrypt(out, in, b) arc4_crypt(out, in, b)

#elif defined(DFU_CIPHER_CHACHA_A) && defined(__thumb__)
    #include "chacha_a.h"
    #define DFU_AES_KEY DFU_AES_KEY_A DFU_AES_KEY_B
    #define aes_init(key) _chacha_init(key)
    #define aes_encrypt(out, in, b) _chacha_crypt(out, in, b)
    #define aes_decrypt(out, in, b) _chacha_crypt(out, in, b)

#elif defined(DFU_CIPHER_CHACHA) || defined(DFU_CIPHER_CHACHA_A)
    #include "chacha.h"
    #define DFU_AES_KEY DFU_AES_KEY_A DFU_AES_KEY_B
    #define aes_init(key) chacha_init(key)
    #define aes_encrypt(out, in, b) chacha_crypt(out, in, b)
    #define aes_decrypt(out, in, b) chacha_crypt(out, in, b)

#else
    #pragma message "no encryption used "
    #undef DFU_USE_CIPHER
    #define CRYPTO_BLKSIZE 1
    #define CRYPTO_NAME "No encryption"
    #define aes_init(...)
    #define aes_encrypt(...)
    #define aes_decrypt(...)
#endif

#if defined(__cplusplus)
    }
#endif
#endif //_CRYPTO_H_
