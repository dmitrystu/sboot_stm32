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

#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
#include "stm32.h"
#include "config.h"
#include "usb.h"
#include "usb_dfu.h"

/* Checking for the EEPROM */
#if (defined(DATA_EEPROM_BASE) || defined(FLASH_EEPROM_BASE)) && (DFU_INTF_EEPROM != _DISABLE)
    #define _EEPROM_ENABLED
#endif

#define _NEXT_IDX   (__COUNTER__ + 3)

/* setting up descriptor indexex */
#if (DFU_DSC_CONFIG == _ENABLE) && defined(DFU_STR_CONFIG)
    #define _CONF_IDX   _NEXT_IDX
#else
    #define _CONF_IDX   NO_DESCRIPTOR
#endif

#if (DFU_DSC_FLASH == _ENABLE) && defined(DFU_STR_FLASH)
    #define _FLASH_IDX  _NEXT_IDX
#else
    #define _FLASH_IDX  NO_DESCRIPTOR
#endif

#if (DFU_DSC_EEPROM == _ENABLE) && defined(DFU_STR_EEPROM) && defined(_EEPROM_ENABLED)
    #define _EEPROM_IDX _NEXT_IDX
#else
    #define _EEPROM_IDX NO_DESCRIPTOR
#endif

#define _countof(a) (sizeof(a)/sizeof(*(a)))

struct config_desc {
    struct usb_config_descriptor    config;
    struct usb_interface_descriptor flash;
#if defined(_EEPROM_ENABLED)
    struct usb_interface_descriptor eeprom;
#endif
    struct usb_dfu_func_desc        dfufunc;
} __attribute__((packed));

static const struct usb_device_descriptor dfu_device_desc = {
    .bLength            = sizeof (struct usb_device_descriptor),
    .bDescriptorType    = USB_DTYPE_DEVICE,
    .bcdUSB             = VERSION_BCD(2,0,0),
    .bDeviceClass       = USB_CLASS_PER_INTERFACE,
    .bDeviceSubClass    = USB_SUBCLASS_NONE,
    .bDeviceProtocol    = USB_PROTO_NONE,
    .bMaxPacketSize0    = DFU_EP0_SIZE,
    .idVendor           = DFU_VENDOR_ID,
    .idProduct          = DFU_DEVICE_ID,
    .bcdDevice          = VERSION_BCD(1,0,0),
    .iManufacturer      = 1,
    .iProduct           = 2,
    .iSerialNumber      = INTSERIALNO_DESCRIPTOR,
    .bNumConfigurations = 1,
};

static const struct config_desc dfu_config_desc = {
    .config = {
        .bLength                = sizeof(struct usb_config_descriptor),
        .bDescriptorType        = USB_DTYPE_CONFIGURATION,
        .wTotalLength           = sizeof(struct config_desc),
        .bNumInterfaces         = 1,
        .bConfigurationValue    = 1,
        .iConfiguration         = _CONF_IDX,
        .bmAttributes           = USB_CFG_ATTR_RESERVED | USB_CFG_ATTR_SELFPOWERED,
        .bMaxPower              = USB_CFG_POWER_MA(100),
    },
    .flash = {
        .bLength                = sizeof(struct usb_interface_descriptor),
        .bDescriptorType        = USB_DTYPE_INTERFACE,
        .bInterfaceNumber       = 0,
        .bAlternateSetting      = 0,
        .bNumEndpoints          = 0,
        .bInterfaceClass        = USB_CLASS_DFU,
        .bInterfaceSubClass     = USB_DFU_SUBCLASS_DFU,
        .bInterfaceProtocol     = USB_DFU_PROTO_DFU,
        .iInterface             = _FLASH_IDX,
    },
#if defined(_EEPROM_ENABLED)
    .eeprom = {
        .bLength                = sizeof(struct usb_interface_descriptor),
        .bDescriptorType        = USB_DTYPE_INTERFACE,
        .bInterfaceNumber       = 0,
        .bAlternateSetting      = 1,
        .bNumEndpoints          = 0,
        .bInterfaceClass        = USB_CLASS_DFU,
        .bInterfaceSubClass     = USB_DFU_SUBCLASS_DFU,
        .bInterfaceProtocol     = USB_DFU_PROTO_DFU,
        .iInterface             = _EEPROM_IDX,
    },
#endif
    .dfufunc = {
        .bLength                = sizeof(struct usb_dfu_func_desc),
        .bDescriptorType        = USB_DTYPE_DFU_FUNCTIONAL,
#if (DFU_CAN_UPLOAD == _ENABLE)
        .bmAttributes           = USB_DFU_ATTR_CAN_DNLOAD | USB_DFU_ATTR_CAN_UPLOAD | USB_DFU_ATTR_MANIF_TOL,
#else
        .bmAttributes           = USB_DFU_ATTR_CAN_DNLOAD | USB_DFU_ATTR_MANIF_TOL,
#endif
        .wDetachTimeout         = DFU_DETACH_TIMEOUT,
        .wTransferSize          = DFU_BLOCKSZ,
        .bcdDFUVersion          = VERSION_BCD(1,1,0),
    },
};

static const struct usb_string_descriptor dfu_lang_sdesc    = USB_ARRAY_DESC(USB_LANGID_ENG_US);
static const struct usb_string_descriptor dfu_manuf_sdesc   = USB_STRING_DESC(DFU_STR_MANUF);
static const struct usb_string_descriptor dfu_product_sdesc = USB_STRING_DESC(DFU_STR_PRODUCT);
#if (_CONF_IDX != NO_DESCRIPTOR)
static const struct usb_string_descriptor dfu_config_sdesc  = USB_STRING_DESC(DFU_STR_CONFIG);
#endif
#if (_FLASH_IDX != NO_DESCRIPTOR)
static const struct usb_string_descriptor dfu_flash_sdesc   = USB_STRING_DESC(DFU_STR_FLASH);
#endif
#if (_EEPROM_IDX != NO_DESCRIPTOR)
static const struct usb_string_descriptor dfu_eeprom_sdesc  = USB_STRING_DESC(DFU_STR_EEPROM);
#endif
static const struct usb_string_descriptor * const dtable[] = {
    &dfu_lang_sdesc,
    &dfu_manuf_sdesc,
    &dfu_product_sdesc,
#if (_CONF_IDX != NO_DESCRIPTOR)
    &dfu_config_sdesc,
#endif
#if (_FLASH_IDX != NO_DESCRIPTOR)
    &dfu_flash_sdesc,
#endif
#if (_EEPROM_IDX != NO_DESCRIPTOR)
    &dfu_eeprom_sdesc,
#endif
};

usbd_respond dfu_get_descriptor(usbd_ctlreq *req, void **address, uint16_t *len) {
    const uint8_t dtype = req->wValue >> 8;
    const uint8_t dindx = req->wValue & 0xFF;
    const void *desc;
    uint16_t dlen = 0;
    switch (dtype) {
    case USB_DTYPE_DEVICE:
        desc = &dfu_device_desc;
        break;
    case USB_DTYPE_CONFIGURATION:
        desc = &dfu_config_desc;
        if (*len >= sizeof(dfu_config_desc)) {
            dlen = sizeof(dfu_config_desc);
        }
        break;
    case USB_DTYPE_STRING:
        if (dindx < _countof(dtable)) {
            desc = dtable[dindx];
        } else {
            return usbd_fail;
        }
        break;
    default:
        return usbd_fail;
    }
    if (dlen == 0) dlen = ((struct usb_string_descriptor*)desc)->bLength;
    *len = dlen;
    *address = (void*)desc;
    return usbd_ack;
}
