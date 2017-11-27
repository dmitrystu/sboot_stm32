#ifndef _MISC_H_
#define _MISC_H_

#if defined(__thumb__)

#define __ror32(a, b) \
({ uint32_t __a = (a); uint32_t __b = (b); \
   __asm__("ror %0, %1" : "+l"(__a) : "l"(__b) : "cc"); \
   __a; })
#define __rol32(a, b) \
({ uint32_t __a = (a); uint32_t __b = (b); \
   __asm__ ("neg %1, %1 \n\t ror %0, %1" : "+l"(__a), "+l"(__b) : : "cc"); \
   __a; })
/*
#define __rol32c(a, b) \
({ uint32_t __a = (a); uint32_t __b = 32 - (b); \
   __asm__ ("ror %0, %1" : "+l"(__a) : "l"(__b) : "cc"); \
   __a; })
*/
#else
#define __ror32(a,b) (((a) >> ((b) & 0x1F)) | ((a) << (0x20 - ((b) & 0x1F))))
#define __rol32(a,b) (((a) << ((b) & 0x1F)) | ((a) >> (0x20 - ((b) & 0x1F))))

#endif /* __thumb__ */

inline static void __memcpy(void *dst, const void *src, uint32_t sz) {
    while(sz--) {
        *(uint8_t*)dst++ = *(uint8_t*)src++;
    }
}

#endif /* _MISC_H_ */
