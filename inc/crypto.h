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
/**
 * @brief Initialize cipher
 */
void aes_init(void);

/**
 * @brief Encrypt data
 * @param out output buffer
 * @param in input buffer
 * @param sz data amount in bytes. must fit block size.
 */
void aes_encrypt(void *out, const void *in, size_t sz);

/**
 * @brief Decrypt data
 * @param out output buffer
 * @param in input buffer
 * @param sz data amount in bytes. must fit block size
 */
void aes_decrypt(void *out, const void *in, size_t sz);

/**
 * @brief Cipher name and mode
 */
extern const char *aes_name;

/**
 * @brief Cipher block size
 */
extern const size_t aes_blksize;

#if defined(__cplusplus)
    }
#endif
#endif //_CRYPTO_H_
