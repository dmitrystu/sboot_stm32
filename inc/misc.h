#ifndef _MISC_H_
#define _MISC_H_

#define __ror32(a,b) (((a) >> ((b) & 0x1F)) | ((a) << (0x20 - ((b) & 0x1F))))
#define __rol32(a,b) (((a) << ((b) & 0x1F)) | ((a) >> (0x20 - ((b) & 0x1F))))

#if defined(__BYTE_ORDER__) && (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#define CPUTOBE32(x)    __builtin_bswap32(x)
#define BE32TOCPU(x)    __builtin_bswap32(x)
#else
#define CPUTOBE32(x)    (x)
#define BE32TOCPU(x)    (x)
#endif


#endif /* _MISC_H_ */
