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
#define DFU_CIPHER_GOST     13  /* GOST R 34.12-2015 "MAGMA" block cipher CBC mode */
#define DFU_CIPHER_RAIDEN   14  /* RAIDEN block cipher CBC mode */
#define DFU_CIPHER_RC5      15  /* Rivest RC5-32/12/128 clock cipher in CBC mode */
#define DFU_CIPHER_RC5_A    16  /* Rivest RC5-32/12/128 clock cipher in CBC mode (ASM) */
#define DFU_CIPHER_SPECK    17  /* SPECK 64/128 block cipher in CBC mode */
#define DFU_CIPHER_XTEA     18  /* XTEA block cipher in CBC mode */
#define DFU_CIPHER_XTEA1    19  /* XTEA-1 block cipher in CBC mode */
#define DFU_CIPHER_BLOWFISH 20  /* Blowfish block cipher in CBC mode */
#define DFU_CIPHER_RTEA     21  /* Ruptor's TEA or Repaired TEA in CBC mode */
/** Modes for using with block cipher */
#define DFU_CIPHER_CBC      0
#define DFU_CIPHER_PCBC     1
#define DFU_CIPHER_CFB      2
#define DFU_CIPHER_OFB      3
#define DFU_CIPHER_CTR      4
#define DFU_CIPHER_ECB      5

/** Checksum definitions. */
#define CRC32FAST           1   /* Lookup table based crc32 algorithm, consumes 1Kb of RAM for the table */
#define CRC32SMALL          2   /* Permutation based crc32 algorithm, no lookup table required but slower */
#define FNV1A32             3   /* Fowler–Noll–Vo 32 bit Hash */
#define FNV1A64             4   /* Fowler–Noll–Vo 64 bit Hash */
#define CRC64FAST           5   /* Lookup table based crc64 algorithm, consumes 2Kb of RAM for the table */
#define CRC64SMALL          6   /* Permutation based crc32 algorithm, no lookup table required but extremly slow */

/* CONFIG STARTS HERE */
/* Skip unwanted dfuDNLOAD_SYNC phase. Slightly improve speed, but don't meets DFU1.1 state diagram */
#define DFU_DNLOAD_NOSYNC   _ENABLE
/** Add extra DFU interface for EEPROM */
#define DFU_INTF_EEPROM     _AUTO
/** Firmware can be uploaded from device */
#define DFU_CAN_UPLOAD      _ENABLE
/** Handle DFU_DETACH request in DFU mode. System reset will be issued. */
#define DFU_DETACH          _ENABLE
/** Whether application image is verified by a checksum algorithm */
#define DFU_VERIFY_CHECKSUM _DISABLE
/** Memory Readout Protection level **/
#define DFU_SEAL_LEVEL      0
/* USB VID */
#define DFU_VENDOR_ID       0x0483
/* USB PID */
#define DFU_DEVICE_ID       0xDF11
/* USB manufacturer string */
#define DFU_STR_MANUF       "Your company name"
/* USB product sting */
#define DFU_STR_PRODUCT     "Secure bootloader"
/* USB string for DFU configureation string descriptor. */
#define DFU_DSC_CONFIG      _ENABLE
#define DFU_STR_CONFIG      "DFU"
/* USB string for DFU flash interface string descriptor. */
#define DFU_DSC_FLASH       _ENABLE
#define DFU_STR_FLASH       "Internal flash"
/* USB string for DFU EEPROM interface sreing descriptor */
#define DFU_DSC_EEPROM      _ENABLE
#define DFU_STR_EEPROM       "Internal EEPROM"
/* USB EP0 size. Must be 8 for USB FS */
#define DFU_EP0_SIZE        8
/* DFU properties */
#define DFU_POLL_TIMEOUT    20
#define DFU_DETACH_TIMEOUT  200
#define DFU_BLOCKSZ         0x80
/* 32 bit DFU bootkey value */
#define DFU_BOOTKEY         0x157F32D4
/* DFU bootkey address. Top of the ram by default. _AUTO, _DISABLE or set address.
 * May be enabled internally. */
#define DFU_BOOTKEY_ADDR    _AUTO
/* DFU bootstrap port/pin settings. Set GPIOx or _DISABLE */
#define DFU_BOOTSTRAP_GPIO  GPIOA
#define DFU_BOOTSTRAP_PIN   1
/* Active bootstrap pin logic level. _HIGH, _LOW */
#define DFU_BOOTSTRAP_LEVEL _LOW
/* Pullup or pulldown settings for the bootstrap pin _AUTO, _DISABLE, _HIGH, _LOW */
#define DFU_BOOTSTRAP_PULL  _AUTO
/* Double reset waiting time in mS. _DISABLE or time in mS */
#define DFU_DBLRESET_MS     300
/* User application address. _AUTO or page aligned address.
 * for _AUTO check __app_start address in output linker map file*/
#define DFU_APP_START       _AUTO
/* User application size. _AUTO or required size in bytes. */
#define DFU_APP_SIZE        _AUTO
/* Cipher to use. set _DISABLE or choose from implemented ciphers */
#define DFU_CIPHER          DFU_CIPHER_RTEA
#define DFU_CIPHER_MODE     DFU_CIPHER_CFB
/** DFU secure key. */
#define DFU_AES_KEY_A       0x2D, 0x4D, 0x61, 0x6B, 0x65, 0x4C, 0x6F, 0x76, \
                            0x65, 0x4E, 0x6F, 0x74, 0x57, 0x61, 0x72, 0x2D
#define DFU_AES_KEY_B       0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, \
                            0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F

/** cipher initialization vector for CBC and CHACHA */
#define DFU_AES_NONCE0      0x11223344
#define DFU_AES_NONCE1      0x55667788
#define DFU_AES_NONCE2      0x99AABBCC

#endif // _DFU_BOOTLOADER_H_
