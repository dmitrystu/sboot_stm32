#ifndef _ROT_H_
#define _ROT_H_

#if defined(__thumb__)

#define __ror(a, b) \
({ uint32_t __a = (a); uint32_t __b = (b); \
   __asm__("ror %0, %1" : "+l"(__a) : "l"(__b) : "cc"); \
   __a; })
#define __rol(a, b) \
({ uint32_t __a = (a); uint32_t __b = (b); \
   __asm__ ("neg %1, %1 \n\t ror %0, %1" : "+l"(__a), "+l"(__b) : : "cc"); \
   __a; })
/*
#define __rolc(a, b) \
({ uint32_t __a = (a); uint32_t __b = 32 - (b); \
   __asm__ ("ror %0, %1" : "+l"(__a) : "l"(__b) : "cc"); \
   __a; })
*/
#else
#define __ror(a,b) (((a) >> ((b) & 0x1F)) | ((a) << (0x20 - ((b) & 0x1F))))
#define __rol(a,b) (((a) << ((b) & 0x1F)) | ((a) >> (0x20 - ((b) & 0x1F))))

#endif /* __thumb__ */

#endif /* _ROT_H_ */
