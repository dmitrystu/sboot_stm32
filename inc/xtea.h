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

#ifndef _XTEA_H_
#define _XTEA_H_
#if defined(__cplusplus)
    extern "C" {
#endif

#define CRYPTO_BLKSIZE 8
#if defined(DFU_CIPHER_XTEA1)
    #define CRYPTO_NAME    "XTEA-1 64/32/128-CBC"
#else
    #define CRYPTO_NAME    "XTEA 64/32/128-CBC"
#endif



void xtea_init(const uint8_t *key);
void xtea_encrypt(uint32_t *out, const uint32_t *in, int32_t bytes);
void xtea_decrypt(uint32_t *out, const uint32_t *in, int32_t bytes);


#if defined(__cplusplus)
    }
#endif
#endif // _XTEA_H_
