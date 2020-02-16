/* This file is the part of the STM32 secure bootloader
 *
 * RC6-32/20/16 block cipher implementation based on
 * RonaldL.Rivest ,M.J.B.Robshaw ,R.Sidney ,andY.L.Yin "The RC6(TM) Block Cipher"
 * http://people.csail.mit.edu/rivest/pubs/RRSY98.pdf
 *
 * Copyright ©2020 Dmitry Filimonchuk <dmitrystu[at]gmail[dot]com>
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

#ifndef _RC6_H_
#define _RC6_H_
#if defined(__cplusplus)
    extern "C" {
#endif

/** @brief Initialize RC6-32/12/16 cipher
 *  @param key pointer to 128-bit key
 */
void rc6_init(const void* key);

/** @brief Encrypt 128-bit block
 *  @param out cipher output
 *  @param in  cipher input
 */
void rc6_encrypt(uint32_t *out, const uint32_t *in);

/** @brief Decrypt 128-bit block
 *  @param out cipher output
 *  @param in  cipher input
 */
void rc6_decrypt(uint32_t *out, const uint32_t *in);

#if defined(__cplusplus)
    }
#endif
#endif // _RC6_H_
