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

#include "config.h"

#if (DFU_VERIFY_CHECKSUM == FNV1A64) || (DFU_VERIFY_CHECKSUM == CRC64ECMA) || \
    (DFU_VERIFY_CHECKSUM == CRC64ECMAF)
    typedef uint64_t checksum_t;
#else //FALLBACK
    typedef uint32_t checksum_t;
#endif

size_t append_checksum(void *data, uint32_t len);
size_t validate_checksum(const void *data, uint32_t len);

#if defined(__cplusplus)
    }
#endif
#endif // _CHECKSUM_H_