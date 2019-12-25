/* This file is the part of the STM32 secure bootloader
 *
 * RC5-32/12/128-CBC block cipher implementation based on
 * Ronald L. Rivest "The RC5 Encryption Algorithm"
 * http://people.csail.mit.edu/rivest/Rivest-rc5rev.pdf
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

#ifndef _RC5_A_H_
#define _RC5_A_H_
#if defined(__cplusplus)
    extern "C" {
#endif

/** @brief Initialize RC5-64/12/128 cipher
 *  @param key pointer to 128-bit key
 *  @note  THUMB assembly version
 */
void _rc5_init(const void* key);

/** @brief Encrypt 64-bit block
 *  @param out cipher output
 *  @param in  cipher input
 */
void _rc5_encrypt(uint32_t *out, const uint32_t *in);

/** @brief Decrypt 64-bit block
 *  @param out cipher output
 *  @param in  cipher input
 */
void _rc5_decrypt(uint32_t *out, const uint32_t *in);

#if defined(__cplusplus)
    }
#endif
#endif // _RC5_H_
