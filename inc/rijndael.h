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

#ifndef _RINJDAEL_H_
#define _RINJDAEL_H_
#if defined(__cplusplus)
    extern "C" {
#endif

#ifndef RIJNDAEL_KEYSIZE
#define RIJNDAEL_KEYSIZE    128
#endif

#ifndef RIJNDAEL_ROM_SBOXES
#define RIJNDAEL_ROM_SBOXES 0
#endif


/** @brief Initialize AES-128/192/256 cipher
 *  @param key pointer to 128-bit key
 */
void rijndael_init(const void* key);

/** @brief Encrypt 128-bit block
 *  @param out cipher output
 *  @param in  cipher input
 */
void rijndael_encrypt(uint32_t *out, const uint32_t *in);

/** @brief Decrypt 128-bit block
 *  @param out cipher output
 *  @param in  cipher input
 */
void rijndael_decrypt(uint32_t *out, const uint32_t *in);

#if defined(__cplusplus)
    }
#endif
#endif // _RINJDAEL_H_
