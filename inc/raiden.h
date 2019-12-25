/* This file is the part of the STM32 secure bootloader
 *
 * Raiden block cipher implementation based on original code developed by
 * Julio César Hernández Castro and Javier Polimón Olabarrieta
 * https://sourceforge.net/projects/raiden-cipher/
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

#ifndef _RAIDEN_H_
#define _RAIDEN_H_
#if defined(__cplusplus)
    extern "C" {
#endif

/** @brief Initialize RAIDEN cipher
 *  @param key pointer to array contains 128-bit key
 */
void raiden_init(const void* key);

/** @brief Encrypt 64-bit block
 *  @param out cipher output
 *  @param in  cipher input
 */
void raiden_encrypt(uint32_t *out, const uint32_t *in);

/** @brief Decrypt 64-bit block
 *  @param out cipher output
 *  @param in  cipher input
 */
void raiden_decrypt(uint32_t *out, const uint32_t *in);

#if defined(__cplusplus)
    }
#endif
#endif // _RAIDEN_H_
