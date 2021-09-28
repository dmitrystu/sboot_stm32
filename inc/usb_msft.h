#ifndef _USB_MSFT_H_
#define _USB_MSFT_H_
#if defined(__cplusplus)
    extern "C" {
#endif

#include <stdint.h>

/* Microsoft OS 1.0 descriptors */

/* Extended Compat ID OS Feature Descriptor Specification */
#define USB_MSFT_REQ_GET_COMPAT_ID_FEATURE_DESCRIPTOR 0x04

/* Table 2. Function Section */
struct usb_msft_compat_id_func_section {
    uint8_t  bInterfaceNumber;
    uint8_t  reserved0[1];
    const char compatibleId[8];
    const char subCompatibleId[8];
    uint8_t  reserved1[6];
} __attribute__((packed));

#define USB_MSFT_COMPAT_ID_FUNCTION_SECTION_SIZE 24

/* Table 1. Header Section */
struct usb_msft_compat_id_desc {
    uint32_t dwLength;
    uint16_t bcdVersion;
    uint16_t wIndex;
    uint8_t  bNumSections;
    uint8_t  reserved[7];
    struct usb_msft_compat_id_func_section functions[];
} __attribute__((packed));

#define USB_MSFT_COMPAT_ID_HEADER_SIZE 16

#if defined(__cplusplus)
}
#endif

#endif /* _USB_MSFT_H_ */
