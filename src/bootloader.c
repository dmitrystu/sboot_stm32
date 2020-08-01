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
#include <stdbool.h>
#include <stddef.h>
#include "config.h"
#include "stm32.h"
#include "usb.h"
#include "usb_dfu.h"
#include "descriptors.h"
#include "flash.h"
#include "crypto.h"

/* Checking for the EEPROM */
#if defined(DATA_EEPROM_BASE)
    #define _EE_START    DATA_EEPROM_BASE
    #define _EE_LENGTH   (DATA_EEPROM_END - DATA_EEPROM_BASE + 1)
#elif defined(FLASH_EEPROM_BASE)
    #define _EE_START    FLASH_EEPROM_BASE
    #define _EE_LENGTH   (FLASH_EEPROM_END - FLASH_EEPROM_BASE + 1 )
#endif

#if (DFU_INTF_EEPROM == _ENABLE) && !defined(_EE_START)
    #error No EEPROM found. Check config !!
#elif ((DFU_INTF_EEPROM == _AUTO) || (DFU_INTF_EEPROM == _ENABLE)) && defined(_EE_START)
    #define _EEPROM_ENABLED
#endif

/* Checking for application start address */
#if (DFU_APP_START == _AUTO)
    #define _APP_START  ((size_t)&__app_start)
#elif ((DFU_APP_START & 0x000007FF) == 0)
    #define _APP_START  DFU_APP_START
#else
    #error DFU_APP_START must be 2k aligned. Check config !!
#endif

/* Checking for application size */
#if (DFU_APP_SIZE == _AUTO)
    #define _APP_LENGTH ((size_t)&__romend - _APP_START)
#else
    #define _APP_LENGTH DFU_APP_SIZE
#endif

/* DFU request buffer size data + request header */
#define DFU_BUFSZ  ((DFU_BLOCKSZ + 3 + 8) >> 2)

extern uint8_t  __app_start;
extern uint8_t  __romend;

static uint32_t dfu_buffer[DFU_BUFSZ];
static usbd_device dfu;

static struct dfu_data_s {
    uint8_t     (*flash)(void *romptr, const void *buf, size_t blksize);
    void        *dptr;
    size_t      remained;
    uint8_t     interface;
    uint8_t     bStatus;
    uint8_t     bState;
} dfu_data;

/** Processing DFU_SET_IDLE request */
static usbd_respond dfu_set_idle(void) {
    aes_init();
    dfu_data.bState = USB_DFU_STATE_DFU_IDLE;
    dfu_data.bStatus = USB_DFU_STATUS_OK;
    switch (dfu_data.interface){
#if defined(_EEPROM_ENABLED)
    case 1:
        dfu_data.dptr = (void*)_EE_START;
        dfu_data.remained = _EE_LENGTH;
        dfu_data.flash = program_eeprom;
        break;
#endif
    default:
        dfu_data.dptr = (void*)_APP_START;
        dfu_data.remained = _APP_LENGTH;
        dfu_data.flash = program_flash;
        break;
    }
    return usbd_ack;
}

extern void System_Reset(void);

static usbd_respond dfu_err_badreq(void) {
    dfu_data.bState  = USB_DFU_STATE_DFU_ERROR;
    dfu_data.bStatus = USB_DFU_STATUS_ERR_STALLEDPKT;
    return usbd_fail;
}

static usbd_respond dfu_upload(usbd_device *dev, size_t blksize) {
    switch (dfu_data.bState) {
#if (DFU_CAN_UPLOAD == _ENABLE)
    case USB_DFU_STATE_DFU_IDLE:
    case USB_DFU_STATE_DFU_UPLOADIDLE:
        if (dfu_data.remained == 0) {
            dev->status.data_count = 0;
            return dfu_set_idle();
        } else if (dfu_data.remained < DFU_BLOCKSZ) {
            blksize = dfu_data.remained;
        }
        aes_encrypt(dev->status.data_ptr, dfu_data.dptr, blksize);
        dev->status.data_count = blksize;
        dfu_data.remained -= blksize;
        dfu_data.dptr += blksize;
        return usbd_ack;
#endif
    default:
        return dfu_err_badreq();
    }
}

static usbd_respond dfu_dnload(void *buf, size_t blksize) {
    switch(dfu_data.bState) {
    case    USB_DFU_STATE_DFU_DNLOADIDLE:
    case    USB_DFU_STATE_DFU_DNLOADSYNC:
    case    USB_DFU_STATE_DFU_IDLE:
        if (blksize == 0) {
            dfu_data.bState = USB_DFU_STATE_DFU_MANIFESTSYNC;
            return usbd_ack;
        }
        if (blksize > dfu_data.remained) {
            dfu_data.bStatus = USB_DFU_STATUS_ERR_ADDRESS;
            dfu_data.bState = USB_DFU_STATE_DFU_ERROR;
            return usbd_ack;
        }
        aes_decrypt(buf, buf, blksize );
        dfu_data.bStatus = dfu_data.flash(dfu_data.dptr, buf, blksize);

        if (dfu_data.bStatus == USB_DFU_STATUS_OK) {
            dfu_data.dptr += blksize;
            dfu_data.remained -= blksize;
#if (DFU_DNLOAD_NOSYNC == _ENABLED)
            dfu_data.bState = USB_DFU_STATE_DFU_DNLOADIDLE;
#else
            dfu_data.bState = USB_DFU_STATE_DFU_DNLOADSYNC;
#endif
            return usbd_ack;
        } else {
            dfu_data.bState = USB_DFU_STATE_DFU_ERROR;
            return usbd_ack;
        }
    default:
        return dfu_err_badreq();
    }
}

static usbd_respond dfu_getstatus(void *buf) {
    /* make answer */
    struct usb_dfu_status *stat = buf;
    stat->bStatus = dfu_data.bStatus;
    stat->bState = dfu_data.bState;
    stat->bPollTimeout = (DFU_POLL_TIMEOUT & 0xFF);
    stat->wPollTimeout = (DFU_POLL_TIMEOUT >> 8);
    stat->iString = NO_DESCRIPTOR;

    switch (dfu_data.bState) {
    case USB_DFU_STATE_DFU_IDLE:
    case USB_DFU_STATE_DFU_DNLOADIDLE:
    case USB_DFU_STATE_DFU_UPLOADIDLE:
    case USB_DFU_STATE_DFU_ERROR:
        return usbd_ack;
    case USB_DFU_STATE_DFU_DNLOADSYNC:
        dfu_data.bState = USB_DFU_STATE_DFU_DNLOADIDLE;
        return usbd_ack;
    case USB_DFU_STATE_DFU_MANIFESTSYNC:
        return dfu_set_idle();
    default:
        return dfu_err_badreq();
    }
}

static usbd_respond dfu_getstate(uint8_t *buf) {
    *buf = dfu_data.bState;
    return usbd_ack;
}

static usbd_respond dfu_abort() {
    switch (dfu_data.bState) {
    case USB_DFU_STATE_DFU_IDLE:
    case USB_DFU_STATE_DFU_DNLOADSYNC:
    case USB_DFU_STATE_DFU_DNLOADIDLE:
    case USB_DFU_STATE_DFU_MANIFESTSYNC:
    case USB_DFU_STATE_DFU_UPLOADIDLE:
        return dfu_set_idle();
    default:
        return dfu_err_badreq();
    }
}

static usbd_respond dfu_clrstatus() {
    if (dfu_data.bState == USB_DFU_STATE_DFU_ERROR)  {
        return dfu_set_idle();
    } else {
        return dfu_err_badreq();
    }
}

static void dfu_reset(usbd_device *dev, uint8_t ev, uint8_t ep) {
    (void)dev;
    (void)ev;
    (void)ep;
    /** TODO : add firmware checkout */
    System_Reset();
}

static usbd_respond dfu_control (usbd_device *dev, usbd_ctlreq *req, usbd_rqc_callback *callback) {
    (void)callback;
    if ((req->bmRequestType  & (USB_REQ_TYPE | USB_REQ_RECIPIENT)) == (USB_REQ_STANDARD | USB_REQ_INTERFACE)) {
        switch (req->bRequest) {
        case USB_STD_SET_INTERFACE:
            if (req->wIndex != 0) return usbd_fail;
            switch (req->wValue) {
            case 0: break;
#if defined(_EEPROM_ENABLED)
            case 1: break;
#endif
            default:
                return usbd_fail;
            }
            dfu_data.interface = req->wValue;
            return dfu_set_idle();
        case USB_STD_GET_INTERFACE:
            req->data[0] = dfu_data.interface;
            return usbd_ack;
        default:
            return usbd_fail;
        }
    }
    if ((req->bmRequestType & (USB_REQ_TYPE | USB_REQ_RECIPIENT)) == (USB_REQ_CLASS | USB_REQ_INTERFACE)) {
        switch (req->bRequest) {
#if (DFU_DETACH == _ENABLE)
        case USB_DFU_DETACH:
            *callback = (usbd_rqc_callback)dfu_reset;
            return usbd_ack;
#endif
        case USB_DFU_DNLOAD:
            return dfu_dnload(req->data, req->wLength);
        case USB_DFU_UPLOAD:
            return dfu_upload(dev, req->wLength);
        case USB_DFU_GETSTATUS:
            return dfu_getstatus(req->data);
        case USB_DFU_CLRSTATUS:
            return dfu_clrstatus();
        case USB_DFU_GETSTATE:
            return dfu_getstate(req->data);
        case USB_DFU_ABORT:
            return dfu_abort();
        default:
            return dfu_err_badreq();
        }
    }
    return usbd_fail;
}


static usbd_respond dfu_config(usbd_device *dev, uint8_t config) {
    switch (config) {
    case 0:
        usbd_reg_event(dev, usbd_evt_reset, 0);
        break;
    case 1:
        usbd_reg_event(dev, usbd_evt_reset, dfu_reset);
        break;
    default:
        return usbd_fail;
    }
    return usbd_ack;
}


static void dfu_init (void) {
    dfu_set_idle();
    usbd_init(&dfu, &usbd_hw, DFU_EP0_SIZE, dfu_buffer, sizeof(dfu_buffer));
    usbd_reg_config(&dfu, dfu_config);
    usbd_reg_control(&dfu, dfu_control);
    usbd_reg_descr(&dfu, dfu_get_descriptor);
    usbd_enable(&dfu, 1);
    usbd_connect(&dfu, 1);
}

int main (void) {
    dfu_init();
    while(1) {
        usbd_poll(&dfu);
    }
}
