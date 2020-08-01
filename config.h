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

#ifndef _DFU_BOOTLOADER_H_
#define _DFU_BOOTLOADER_H_

/* Internal variables. Do not touch this section */
#define _AUTO              -1   /* set automatically */
#define _DISABLE            0   /* disable feature */
#define _ENABLE             1   /* enable feature */
#define _LOW                2
#define _HIGH               3
/** DFU cipher definitions. */
#define DFU_CIPHER_ARC4     10  /* ARCFOUR (Rivest RC-4) stream cipher */
#define DFU_CIPHER_CHACHA   11  /* RFC7539-CHACHA20 stream cipher */
#define DFU_CIPHER_CHACHA_A 12  /* RFC7539-CHACHA20 stream cipher (ASM) */
#define DFU_CIPHER_GOST     13  /* GOST R 34.12-2015 "MAGMA" block cipher */
#define DFU_CIPHER_RAIDEN   14  /* RAIDEN block cipher */
#define DFU_CIPHER_RC5      15  /* Rivest RC5-32/12/128 clock cipher */
#define DFU_CIPHER_RC5_A    16  /* Rivest RC5-32/12/128 clock cipher (ASM) */
#define DFU_CIPHER_SPECK    17  /* SPECK 64/128 block cipher */
#define DFU_CIPHER_XTEA     18  /* XTEA block cipher */
#define DFU_CIPHER_XTEA1    19  /* XTEA-1 block cipher */
#define DFU_CIPHER_BLOWFISH 20  /* Blowfish block cipher */
#define DFU_CIPHER_RTEA     21  /* Ruptor's TEA or Repaired TEA */
#define DFU_CIPHER_RC6      22  /* Rivest RC6-32/20/128 block cipher */
#define DFU_CIPHER_RC6_A    23  /* Rivest RC6-32/20/128 block cipher (ASM)*/
#define DFU_CIPHER_RIJNDAEL 24  /* Rinjdael AES-128 block cipher */
#define DFU_CIPHER_MAGMA    25  /* GOST R 34.12-2015 "MAGMA" (Endianess fixed) block cipher */
/** Modes for using with block cipher */
#define DFU_CIPHER_ECB      0   /* Electronic Codebook (ECB) */
#define DFU_CIPHER_CBC      1   /* Cipher Block Chaining (CBC) */
#define DFU_CIPHER_PCBC     2   /* Propagating Cipher Block Chaining (PCBC) */
#define DFU_CIPHER_CFB      3   /* Cipher Feedback (CFB) */
#define DFU_CIPHER_OFB      4   /* Output Feedback (OFB) */
#define DFU_CIPHER_CTR      5   /* Counter (CTR) */

/** Checksum definitions. */
#define CRC32FAST           1   /* Lookup table based crc32 algorithm, consumes 1Kb of RAM for the table */
#define CRC32SMALL          2   /* Permutation based crc32 algorithm, no lookup table required but slower */
#define FNV1A32             3   /* Fowler–Noll–Vo 32 bit Hash */
#define FNV1A64             4   /* Fowler–Noll–Vo 64 bit Hash */
#define CRC64FAST           5   /* Lookup table based crc64 algorithm, consumes 2Kb of RAM for the table */
#define CRC64SMALL          6   /* Permutation based crc32 algorithm, no lookup table required but extremly slow */

#define __STR(x) #x
#define STR(x) __STR(x)

#ifdef DFU_USER_CONFIG
#include STR(DFU_USER_CONFIG)
#endif

/* DEFAULT CONFIG STARTS HERE */
/* Skip unwanted dfuDNLOAD_SYNC phase. Slightly improve speed, but don't meets DFU1.1 state diagram */
#ifndef DFU_DNLOAD_NOSYNC
#define DFU_DNLOAD_NOSYNC   _ENABLE
#endif
/** Add extra DFU interface for EEPROM */
#ifndef DFU_INTF_EEPROM
#define DFU_INTF_EEPROM     _AUTO
#endif
/** Firmware can be uploaded from device */
#ifndef DFU_CAN_UPLOAD
#define DFU_CAN_UPLOAD      _ENABLE
#endif
/** Handle DFU_DETACH request in DFU mode. System reset will be issued. */
#ifndef DFU_DETACH
#define DFU_DETACH          _ENABLE
#endif
/** Whether application image is verified by a checksum algorithm */
#ifndef DFU_VERIFY_CHECKSUM
#define DFU_VERIFY_CHECKSUM _DISABLE
#endif
/** Memory Readout Protection level **/
#ifndef DFU_SEAL_LEVEL
#define DFU_SEAL_LEVEL      0
#endif
/* USB VID */
#ifndef DFU_VENDOR_ID
#define DFU_VENDOR_ID       0x0483
#endif
/* USB PID */
#ifndef DFU_DEVICE_ID
#define DFU_DEVICE_ID       0xDF11
#endif
/* USB manufacturer string */
#ifndef DFU_STR_MANUF
#define DFU_STR_MANUF       "Your company name"
#endif
/* USB product sting */
#ifndef DFU_STR_PRODUCT
#define DFU_STR_PRODUCT     "Secure bootloader"
#endif
/* USB string for DFU configureation string descriptor. */
#ifndef DFU_DSC_CONFIG
#define DFU_DSC_CONFIG      _ENABLE
#endif
#ifndef DFU_STR_CONFIG
#define DFU_STR_CONFIG      "DFU"
#endif
/* USB string for DFU flash interface string descriptor. */
#ifndef DFU_DSC_FLASH
#define DFU_DSC_FLASH       _ENABLE
#endif
#ifndef DFU_STR_FLASH
#define DFU_STR_FLASH       "Internal flash"
#endif
/* USB string for DFU EEPROM interface sreing descriptor */
#ifndef DFU_DSC_EEPROM
#define DFU_DSC_EEPROM      _ENABLE
#endif
#ifndef DFU_STR_EEPROM
#define DFU_STR_EEPROM       "Internal EEPROM"
#endif
/* USB EP0 size. Must be 8 for USB FS */
#define DFU_EP0_SIZE        8
/* DFU properties */
#ifndef DFU_POLL_TIMEOUT
#define DFU_POLL_TIMEOUT    20
#endif
#ifndef DFU_DETACH_TIMEOUT
#define DFU_DETACH_TIMEOUT  200
#endif
#ifndef DFU_BLOCKSZ
#define DFU_BLOCKSZ         0x80
#endif
/* 32 bit DFU bootkey value */
#ifndef DFU_BOOTKEY
#define DFU_BOOTKEY         0x157F32D4
#endif
/* DFU bootkey address. Top of the ram by default. _AUTO, _DISABLE or set address.
 * May be enabled internally. */
#ifndef DFU_BOOTKEY_ADDR
#define DFU_BOOTKEY_ADDR    _AUTO
#endif
/* DFU bootstrap port/pin settings. Set GPIOx or _DISABLE */
#ifndef DFU_BOOTSTRAP_GPIO
#define DFU_BOOTSTRAP_GPIO  GPIOA
#endif
#ifndef DFU_BOOTSTRAP_PIN
#define DFU_BOOTSTRAP_PIN   1
#endif
/* Active bootstrap pin logic level. _HIGH, _LOW */
#ifndef DFU_BOOTSTRAP_LEVEL
#define DFU_BOOTSTRAP_LEVEL _LOW
#endif
/* Pullup or pulldown settings for the bootstrap pin _AUTO, _DISABLE, _HIGH, _LOW */
#ifndef DFU_BOOTSTRAP_PULL
#define DFU_BOOTSTRAP_PULL  _AUTO
#endif
/* Double reset waiting time in mS. _DISABLE or time in mS */
#ifndef DFU_DBLRESET_MS
#define DFU_DBLRESET_MS     300
#endif
/* User application address. _AUTO or page aligned address.
 * for _AUTO check __app_start address in output linker map file*/
#ifndef DFU_APP_START
#define DFU_APP_START       _AUTO
#endif
/* User application size. _AUTO or required size in bytes. */
#ifndef DFU_APP_SIZE
#define DFU_APP_SIZE        _AUTO
#endif
/* Cipher to use. set _DISABLE or choose from implemented ciphers */
#ifndef DFU_CIPHER
#define DFU_CIPHER          DFU_CIPHER_RC5
#endif
#ifndef DFU_CIPHER_MODE
#define DFU_CIPHER_MODE     DFU_CIPHER_CBC
#endif
/** DFU secure key. */
#define DFU_AES_KEY_A       0x2D, 0x4D, 0x61, 0x6B, 0x65, 0x4C, 0x6F, 0x76, \
                            0x65, 0x4E, 0x6F, 0x74, 0x57, 0x61, 0x72, 0x2D
#define DFU_AES_KEY_B       0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, \
                            0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F
#ifndef DFU_AES_KEY_128
#define DFU_AES_KEY_128     DFU_AES_KEY_A
#endif

#ifndef DFU_AES_KEY_192
#define DFU_AES_KEY_192     0x2D, 0x4D, 0x61, 0x6B, 0x65, 0x4C, 0x6F, 0x76, \
                            0x65, 0x4E, 0x6F, 0x74, 0x57, 0x61, 0x72, 0x2D, \
                            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
#endif

#ifndef DFU_AES_KEY_256
#define DFU_AES_KEY_256     DFU_AES_KEY_A, DFU_AES_KEY_B
#endif

/** cipher initialization vector for block cipher and CHACHA */
#ifndef DFU_AES_IV_64
#define DFU_AES_IV_64       0x44, 0x33, 0x22, 0x11, 0x88, 0x77, 0x66, 0x55
#endif

#ifndef DFU_AES_IV_96
#define DFU_AES_IV_96       0x44, 0x33, 0x22, 0x11, 0x88, 0x77, 0x66, 0x55, \
                            0xCC, 0xBB, 0xAA, 0x99
#endif

#ifndef DFU_AES_IV_128
#define DFU_AES_IV_128      0x44, 0x33, 0x22, 0x11, 0x88, 0x77, 0x66, 0x55,\
                            0xCC, 0xBB, 0xAA, 0x99, 0x44, 0x33, 0x22, 0x11
#endif

#endif // _DFU_BOOTLOADER_H_
