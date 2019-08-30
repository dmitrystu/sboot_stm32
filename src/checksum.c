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

#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include "config.h"
#include "checksum.h"


#if ((DFU_VERIFY_CHECKSUM == CRC32FAST) || (DFU_VERIFY_CHECKSUM == CRC32SMALL))
    typedef uint32_t checksum_t;
    const char *checksum_name = "CRC-32";
    #define CRC_POLY 0xEDB88320UL
    #define CRC_INIT 0xFFFFFFFFUL

#elif ((DFU_VERIFY_CHECKSUM == CRC64FAST) || (DFU_VERIFY_CHECKSUM == CRC64SMALL))
    typedef uint64_t checksum_t;
    const char *checksum_name = "CRC-64";
    #define CRC_POLY 0x95AC9329AC4BC9B5ULL
    #define CRC_INIT 0xFFFFFFFFFFFFFFFFULL

#elif (DFU_VERIFY_CHECKSUM == FNV1A32)
    typedef uint32_t checksum_t;
    const char *checksum_name = "FNV1A-32";
    #define FNV_OFFS 0x811c9dc5UL
    #define FNV_PRIM 16777619UL

#elif (DFU_VERIFY_CHECKSUM == FNV1A64)
    const char *checksum_name = "FNV1A-64";
    typedef uint64_t checksum_t;
    #define FNV_OFFS 0xcbf29ce484222325ULL
    #define FNV_PRIM 1099511628211ULL

#else
    const char *checksum_name = "NONE";
    typedef uint32_t checksum_t;
#endif

/* Function prototypes */
inline static void init_checksum(checksum_t *checksum);
inline static void update_checksum(checksum_t *checksum, uint8_t data);


/* Function implementations */
#if ((DFU_VERIFY_CHECKSUM == CRC32FAST) || (DFU_VERIFY_CHECKSUM == CRC64FAST))

static checksum_t table[0x100];

static void init_checksum(checksum_t *checksum) {
    for (int j = 0; j < 256; j++) {
        uint64_t cs = j;
        for (int i = 0; i < 8; i++) {
            if (cs & 0x01) {
                cs = (cs >> 1) ^ CRC_POLY;
            } else {
                cs = (cs >> 1);
            }
        }
        table[j] = cs;
    }
    *checksum = CRC_INIT;
}

static void update_checksum(checksum_t *checksum, uint8_t data) {
    data ^= *checksum & 0xFF;
    *checksum = (*checksum >> 8) ^ table[data];
}

#elif ((DFU_VERIFY_CHECKSUM == CRC32SMALL) || (DFU_VERIFY_CHECKSUM == CRC64SMALL))

static void init_checksum(checksum_t *checksum) {
    *checksum = CRC_INIT;
}

static void update_checksum(checksum_t *checksum, uint8_t data) {
    *checksum ^= data;
    for (int i =0; i < 8; i++) {
        if (*checksum & 0x01) {
            *checksum = (*checksum >> 1) ^ CRC_POLY;
        } else {
            *checksum = (*checksum >> 1);
        }
    }
}

#elif ((DFU_VERIFY_CHECKSUM == FNV1A32) || (DFU_VERIFY_CHECKSUM == FNV1A64))

static void init_checksum(checksum_t *checksum) {
    *checksum = FNV_OFFS;
}

static void update_checksum(checksum_t *checksum, uint8_t data) {
    *checksum = (*checksum ^ data) * FNV_PRIM;
}

#else
typedef uint32_t checksum_t;
static void update_checksum(checksum_t *cs, uint8_t data) { }
static void init_checksum(checksum_t *cs) { *cs = 0; }
#endif

size_t append_checksum(void *data, uint32_t len) {
    checksum_t cs;
    uint8_t *buf = data;
    init_checksum(&cs);
    while (len--) {
        update_checksum(&cs, *buf);
        buf++;
    }
    memcpy(buf, &cs, sizeof(cs));
    return sizeof(checksum_t);
}

size_t validate_checksum(const void *data, uint32_t len)  {
    checksum_t cs, tcs;
    const uint8_t *buf = data;
    init_checksum(&cs);
    memcpy(&tcs, buf, sizeof(checksum_t));
    while(1) {
        if (cs == tcs) return (size_t)(buf - (uint8_t *)data);
        if (sizeof(checksum_t) >= len--) break;
        update_checksum(&cs, (uint8_t)(tcs & 0xFF));
        tcs = (tcs & ~0xFF) | buf[sizeof(checksum_t)];
        tcs = (tcs >> 8) | (tcs << (8 * sizeof(checksum_t) - 8));
        buf++;
//        if (!memcmp((void*)buf, &cs, sizeof(checksum_t))) {
//            return (size_t)(buf - (uint8_t *)data);
//        }
//        update_checksum(&cs, *buf++);
    }
    return 0;
}



