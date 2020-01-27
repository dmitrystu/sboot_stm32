#ifndef _MISC_H_
#define _MISC_H_

#define __ror32(a,b) (((a) >> ((b) & 0x1F)) | ((a) << (0x20 - ((b) & 0x1F))))
#define __rol32(a,b) (((a) << ((b) & 0x1F)) | ((a) >> (0x20 - ((b) & 0x1F))))

#endif /* _MISC_H_ */
