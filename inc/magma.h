/* This file is the part of the STM32 secure bootloader
 *
 * GOST R 34.12-2015 "MAGMA" block cipher implementation based on
 * official GOST R 34.12-2015 national standard of the Russian Federation
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

#ifndef _MAGMA_H_
#define _MAGMA_H_
#if defined(__cplusplus)
    extern "C" {
#endif

/** @brief Initialize GOST R 34.12-2015 "MAGMA" 64-bit block cipher
 *  @param key pointer to array contains 256-bit key
 */
void magma_init(const void* key);

/** @brief Encrypt 64-bit block
 *  @param out cipher output
 *  @param in  cipher input
 */
void magma_encrypt(uint32_t *out, const uint32_t *in);

/** @brief Decrypt 64-bit block
 *  @param out cipher output
 *  @param in  cipher input
 */
void magma_decrypt(uint32_t *out, const uint32_t *in);

#if defined(__cplusplus)
    }
#endif
#endif // _MAGMA_H_
