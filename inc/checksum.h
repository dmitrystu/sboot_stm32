/* This file is the part of the STM32 secure bootloader
 *
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

#include "config.h"

#if (!defined(DFU_VERIFY_CHECKSUM) || ( defined(DFU_VERIFY_CHECKSUM) && (DFU_VERIFY_CHECKSUM == _DISABLE)) )
#define checksum_length() 0
#else

#if defined(__cplusplus)
    extern "C" {
#endif

    uint32_t checksum_length(void);
    uint32_t checksum_create(void *data, uint32_t length);

#if defined(__cplusplus)
    }
#endif

#endif
#endif
