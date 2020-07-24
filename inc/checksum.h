/* This file is the part of the STM32 secure bootloader
 *
 * Copyright ©2016 Dmitry Filimonchuk <dmitrystu[at]gmail[dot]com>
 * Copyright 2019 by Tsien (UK) Ltd.
 *
 * Author: Adrian Carpenter <tech[at]tsien[dot]com>
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
 *
 */

#ifndef _CHECKSUM_H_
#define _CHECKSUM_H_
#if defined(__cplusplus)
    extern "C" {
#endif

extern const char *checksum_name;
extern const size_t checksum_length;

/**
 * @brief Calculate and append checksum to data.
 * @param data data buffer
 * @param len  data length
 * @param bsize data buffer size
 * @return size_t length of the data with appended checksum or 0 if no enought space in buffer
 */
size_t append_checksum(void *data, size_t len, size_t bsize);

/**
 * @brief Find and derify checksum.
 * @param data data buffer
 * @param bsize length of the data buffer
 * @return size_t length of the data w/o checksum or 0 if no data with correct checksum found
 */
size_t validate_checksum(const void *data, size_t bsize);

#if defined(__cplusplus)
    }
#endif
#endif // _CHECKSUM_H_