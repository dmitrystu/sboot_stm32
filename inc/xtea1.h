/* This file is the part of the STM32 secure bootloader
 *
 * eXtended TEA block cipher based on:
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

#ifndef _XTEA1_H_
#define _XTEA1_H_
#if defined(__cplusplus)
    extern "C" {
#endif

/** @brief Initialize XTEA-1 block cipher
 *  @param key pointer to array contains 128-bit key
 */
void xtea1_init(const void* key);

/** @brief Encrypt 64-bit block
 *  @param out cipher output
 *  @param in  cipher input
 */
void xtea1_encrypt(uint32_t *out, const uint32_t *in);

/** @brief Decrypt 64-bit block
 *  @param out cipher output
 *  @param in  cipher input
 */
void xtea1_decrypt(uint32_t *out, const uint32_t *in);

#if defined(__cplusplus)
    }
#endif
#endif // _XTEA1_H_
