/* This file is the part of the STM32 secure bootloader
 *
 * ChaCha20 stream cipher implementation based on RFC7539
 * "ChaCha20 and Poly1305 for IETF Protocols"
 * https://tools.ietf.org/html/rfc7539
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

#ifndef _CHACHA_A_H_
#define _CHACHA_A_H_
#if defined(__cplusplus)
    extern "C" {
#endif

/**
 * @brief initialize CHACHA-20 stream cipher
 * @param key  256-bit ket
 * @param nonce 96-bit IV
 */
void _chacha_init(const void *key, const void *nonce);

/** @brief Encrypt/Decrypt byte
 *  @param out cipher output
 *  @param in  cipher input
 */
void _chacha_crypt(void *out, const void *in);

#if defined(__cplusplus)
    }
#endif
#endif //_CHACHA_A_H_
