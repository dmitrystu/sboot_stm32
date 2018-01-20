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
#if defined(__cplusplus)
    extern "C" {
#endif

/** Skip unwanted dfuDNLOAD_SYNC phase. Slightly improve speed, but don't meets DFU1.1 state diagram */
#define DFU_DNLOAD_NOSYNC
/** Add extra DFU interface for EEPROM */
//#define DFU_INTF_EEPROM
/** Firmware can be uploaded from device */
#define DFU_CAN_UPLOAD

/** Handle DFU_DETACH request in DFU mode. System reset will be issued. */
#define DFU_DETACH_ENABLED

/** Shrinks ISR vector table to core peripherals */
#define DFU_NO_EXTINT

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
/* USB string for DFU flash interface */
#define DFU_STR_INTF0       "Internal flash"
/* USB string for DFU EEPROM interface */
#define DFU_STR_INTF1       "Internal EEPROM"
/* USB EP0 size */
#define DFU_EP0_SIZE        8
/* DFU properties */
#define DFU_POLL_TIMEOUT    20
#define DFU_DETACH_TIMEOUT  200
#define DFU_BLOCKSZ         0x80
/* 32 bit DFU bootkey value */
#define DFU_BOOTKEY         0x157F32D4
/* DFU bootkey address. Top of the ram by default */
#define DFU_BOOTKEY_ADDR    __stack
/* DFU bootstrap pin settings. Comment it to disable this feature */
#define DFU_BOOTSTRAP_GPIO  GPIOA
#define DFU_BOOTSTRAP_PIN   1
/* Double reset waiting time in mS. Set to 0 to disable this feature */
#define DFU_DBLRESET_MS     300
/* User application address. Sets on linkage. */
#define DFU_USER_APP        __app_start

/** DFU cipher selection. Block ciphers runs in CBC mode
 *  _A suffix means assembly implementation
 */
//#define DFU_CIPHER_ARC4
//#define DFU_CIPHER_CHACHA
//#define DFU_CIPHER_CHACHA_A
//#define DFU_CIPHER_GOST
//#define DFU_CIPHER_RAIDEN
//#define DFU_CIPHER_RC5
//#define DFU_CIPHER_RC5_A
//#define DFU_CIPHER_SPECK
//#define DFU_CIPHER_XTEA
#define DFU_CIPHER_XTEA1

/** DFU secure key. */
#define DFU_AES_KEY_A       0x2D, 0x4D, 0x61, 0x6B, 0x65, 0x4C, 0x6F, 0x76, \
                            0x65, 0x4E, 0x6F, 0x74, 0x57, 0x61, 0x72, 0x2D
#define DFU_AES_KEY_B       0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, \
                            0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F

/** cipher initialization vector for CBC and CHACHA */
#define DFU_AES_NONCE0      0x11223344
#define DFU_AES_NONCE1      0x55667788
#define DFU_AES_NONCE2      0x99AABBCC

#if defined(__cplusplus)
    }
#endif
#endif // _DFU_BOOTLOADER_H_
