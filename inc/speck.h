/* This file is the part of the STM32 secure bootloader
 *
 * SPECK 64/128-CBC block cipher implementation based on
 * "The Simon and Speck Families Of Lightwieght Block Ciphers"
 * http://eprint.iacr.org/2013/404.pdf
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

#ifndef _SPECK_H_
#define _SPECK_H_
#if defined(__cplusplus)
    extern "C" {
#endif

#define CRYPTO_BLKSIZE 8
#define CRYPTO_NAME    "SPECK 64/128-CBC"

void speck_init(const void* key);
void speck_encrypt(uint32_t *out, const uint32_t *in);
void speck_decrypt(uint32_t *out, const uint32_t *in);


#if defined(__cplusplus)
    }
#endif
#endif // _SPECK_H_
