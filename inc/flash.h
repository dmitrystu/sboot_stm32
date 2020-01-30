/* This file is the part of the STM32 secure bootloader
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

#ifndef _FLASH_H_
#define _FLASH_H_
#if defined(__cplusplus)
    extern "C" {
#endif
__attribute__((long_call)) uint8_t program_eeprom(void *romaddr, const void *buffer, size_t blksize);
__attribute__((long_call)) uint8_t program_flash(void *romaddr, const void *buffer, size_t blksize);
__attribute__((long_call)) uint8_t seal_flash(void);
#if defined(__cplusplus)
    }
#endif
#endif // _FLASH_H_
