#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "rc5.h"
#include "gost.h"
#include "speck.h"
#include "xtea.h"
#include "xtea1.h"
#include "rtea.h"
#include "raiden.h"
#include "blowfish.h"
#include "chacha.h"
#include "arc4.h"
#include "rc6.h"
#include "rijndael.h"
#include "magma.h"

#define _countof(x) (sizeof(x) / sizeof(*x))

typedef struct test_s {
    const size_t    blocksize;
    const char*     key;
    const char*     name;
    const char*     plain;
    const char*     cipher;
    void (*init)(const void *key);
    void (*encrypt)(uint32_t*, const uint32_t*);
    void (*decrypt)(uint32_t*, const uint32_t*);
} test_t;

/* wrappers for the stream ciphers */

static void arc4_enc128(uint32_t* out, const uint32_t* in) {
    uint8_t *o = (uint8_t*)out;
    const uint8_t *i = (const uint8_t*)in;
    for (int j = 0; j < 16; j++) {
        arc4_crypt(o, i);
        o++;
        i++;
    }
}

static void chaha_init_512(const void* key) {
    const uint8_t nonce[] = {0x00, 0x00, 0x00, 0x09, 0x00, 0x00, 0x00, 0x4a, 0x00, 0x00, 0x00, 0x00};
    chacha_init(key, nonce);
}

static void chacha_enc_512(uint32_t* out, const uint32_t* in) {
    uint8_t *o = (uint8_t*)out;
    const uint8_t *i = (const uint8_t*)in;
    for (int j = 0; j < 64; j++) {
        chacha_crypt(o, i);
        o++;
        i++;
    }
}

const test_t data[] = {
    {
        .blocksize = 8,
        .name    = "RC5-32-12-16 NESSIE-S8V1",
        .key     = "2B D6 45 9F 82 C5 B3 00 95 2C 49 10 48 81 FF 48",
        .plain   = "63 8B 3A 5E F7 2B 66 3F",
        .cipher  = "EA 02 47 14 AD 5C 4D 84",
        .init    = rc5_init,
        .encrypt = rc5_encrypt,
        .decrypt = rc5_decrypt,
    },
    {
        .blocksize = 8,
        .name    = "SPECK 64/128 Standard",
        .key     = "00 01 02 03 08 09 0A 0B 10 11 12 13 18 19 1A 1B",
        .plain   = "2D 43 75 74 74 65 72 3B",
        .cipher  = "8B 02 4E 45 48 A5 6F 8C",
        .init    = speck_init,
        .encrypt = speck_encrypt,
        .decrypt = speck_decrypt,
    },
    {
        .blocksize = 8,
        .name    = "XTEA 64/32/128 NOAA-V1(BE32->LE32)",
        .key     = "03 02 01 00 07 06 05 04 0B 0A 09 08 0F 0E 0D 0C",
        .plain   = "44 43 42 41 48 47 46 45",
        .cipher  = "D0 F3 7D 49 B5 2C 61 72",
        .init    = xtea_init,
        .encrypt = xtea_encrypt,
        .decrypt = xtea_decrypt,
    },
    {
        .blocksize = 8,
        .name    = "XTEA1 64/32/128 Custom",
        .key     = "01 23 45 67 89 AB CD EF FE DC BA 98 76 54 32 10",
        .plain   = "F0 D5 D4 C9 CE F7 CF D2",
        .cipher  = "8B 3B F4 25 0D 76 EF 2A",
        .init    = xtea1_init,
        .encrypt = xtea1_encrypt,
        .decrypt = xtea1_decrypt,
    },
   {
        .blocksize = 8,
        .name    = "GOST R 34.12-2015 \"MAGMA\" Standard(BE64->LE64)",
        .key     = "FF EE DD CC BB AA 99 88 77 66 55 44 33 22 11 00"
                   "F0 F1 F2 F3 F4 F5 F6 F7 F8 F9 FA FB FC FD FE FF",
        .plain   = "10 32 54 76 98 BA DC FE",
        .cipher  = "3D CA D8 C2 E5 01 E9 4E",
        .init    = gost_init,
        .encrypt = gost_encrypt,
        .decrypt = gost_decrypt,
    },
   {
        .blocksize = 8,
        .name    = "GOST R 34.12-2015 \"MAGMA\" (FIXED) Standard",
        .key     = "FF EE DD CC BB AA 99 88 77 66 55 44 33 22 11 00"
                   "F0 F1 F2 F3 F4 F5 F6 F7 F8 F9 FA FB FC FD FE FF",
        .plain   = "FE DC BA 98 76 54 32 10",
        .cipher  = "4E E9 01 E5 C2 D8 CA 3D",
        .init    = magma_init,
        .encrypt = magma_encrypt,
        .decrypt = magma_decrypt,
    },
    {
        .blocksize = 8,
        .name    = "RTEA 64/64/256 Custom",
        .key     = "01 23 45 67 89 AB CD EF FE DC BA 98 76 54 32 10"
                   "FE DC BA 98 76 54 32 10 01 23 45 67 89 AB CD EF",
        .plain   = "BB 4F 5F E8 D2 FC 01 39",
        .cipher  = "3D D8 8A BB 2B 5E 41 99",
        .init    = rtea_init,
        .encrypt = rtea_encrypt,
        .decrypt = rtea_decrypt,
    },
    {
        .blocksize = 8,
        .name    = "RAIDEN 64/16/128 Custom",
        .key     = "71 0B 18 F0 CA 9F 8E EE 6D B2 0C 5E 6A 91 F8 EC",
        .plain   = "CF F3 F2 E8 ED C2 EE F0",
        .cipher  = "D7 D9 0A D8 29 32 A0 0F",
        .init    = raiden_init,
        .encrypt = raiden_encrypt,
        .decrypt = raiden_decrypt,
    },
    {
        .blocksize = 8,
        .name    = "BLOWFISH 64/16/256 Custom",
        .key     = "01 23 45 67 89 AB CD EF FE DC BA 98 76 54 32 10"
                   "FE DC BA 98 76 54 32 10 01 23 45 67 89 AB CD EF",
        .plain   = "4F F7 6D C5 8D 0D 48 92",
        .cipher  = "CF F3 F2 E8 ED C2 EE F0",
        .init    = blowfish_init,
        .encrypt = blowfish_encrypt,
        .decrypt = blowfish_decrypt,
    },
    {
        .blocksize = 16,
        .name    = "RC4 RFC6229 page 8",
        .key     = "EB B4 62 27 C6 CC 8B 37 64 19 10 83 32 22 77 2A",
        .plain   = "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00",
        .cipher  = "72 0C 94 B6 3E DF 44 E1 31 D9 50 CA 21 1A 5A 30",
        .init    = arc4_init,
        .encrypt = arc4_enc128,
        .decrypt = arc4_enc128,
    },
    {
        .blocksize = 64,
        .name    = "CHACHA-20 RFC7539 page 9",
        .key     = "00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F"
                   "10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F",
        .plain   = "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
                   "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
                   "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
                   "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00",
        .cipher  = "10 F1 E7 E4 D1 3B 59 15 50 0F DD 1F A3 20 71 C4 "
                   "C7 D1 F4 C7 33 C0 68 03 04 22 AA 9A C3 D4 6C 4E "
                   "D2 82 64 46 07 9F AA 09 14 C2 D7 05 D9 8B 02 A2 "
                   "B5 12 9C D1 DE 16 4E B9 CB D0 83 E8 A2 50 3C 4E",
        .init    = chaha_init_512,
        .encrypt = chacha_enc_512,
        .decrypt = chacha_enc_512,
    },
    {
        .blocksize = 16,
        .name    = "RC6-32/20/16 IETF",
        .key     = "00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F",
        .plain   = "00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F",
        .cipher  = "3A 96 F9 C7 F6 75 5C FE 46 F0 0E 3D CD 5D 2A 3C",
        .init    = rc6_init,
        .encrypt = rc6_encrypt,
        .decrypt = rc6_decrypt,
    },
#if (RIJNDAEL_KEYSIZE == 128)
    {
        .blocksize = 16,
        .name    = "AES-128 NIST AESAVS C.1 Vector 2",
        .key     = "CA EA 65 CD BB 75 E9 16 9E CD 22 EB E6 E5 46 75",
        .plain   = "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00",
        .cipher  = "6E 29 20 11 90 15 2D F4 EE 05 81 39 DE F6 10 BB",
        .init    = rijndael_init,
        .encrypt = rijndael_encrypt,
        .decrypt = rijndael_decrypt,
    },
    {
        .blocksize = 16,
        .name    = "AES-128 FIPS-197",
        .key     = "00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F",
        .plain   = "00 11 22 33 44 55 66 77 88 99 AA BB CC DD EE FF",
        .cipher  = "69 C4 E0 D8 6A 7B 04 30 D8 CD B7 80 70 B4 C5 5A",
        .init    = rijndael_init,
        .encrypt = rijndael_encrypt,
        .decrypt = rijndael_decrypt,
    },
#elif (RIJNDAEL_KEYSIZE == 192)
    {
        .blocksize = 16,
        .name    = "AES-192 NIST AESAVS C.2 Vector 3",
        .key     = "A8 A2 82 EE 31 C0 3F AE 4F 8E 9B 89 30 D5 47 3C"
                  " 2E D6 95 A3 47 E8 8B 7C",
        .plain   = "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00",
        .cipher  = "93 F3 27 0C FC 87 7E F1 7E 10 6C E9 38 97 9C B0",
        .init    = rijndael_init,
        .encrypt = rijndael_encrypt,
        .decrypt = rijndael_decrypt,
    },
    {
        .blocksize = 16,
        .name    = "AES-192 FIPS-197",
        .key     = "00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F"
                  " 10 11 12 13 14 15 16 17",
        .plain   = "00 11 22 33 44 55 66 77 88 99 AA BB CC DD EE FF",
        .cipher  = "DD A9 7C A4 86 4C DF E0 6E AF 70 A0 EC 0D 71 91",
        .init    = rijndael_init,
        .encrypt = rijndael_encrypt,
        .decrypt = rijndael_decrypt,
    },
#elif (RIJNDAEL_KEYSIZE == 256)
    {
        .blocksize = 16,
        .name    = "AES-256 NIST AESAVS C.3 Vector 1",
        .key     = "C4 7B 02 94 DB BB EE 0F EC 47 57 F2 2F FE EE 35"
                  " 87 CA 47 30 C3 D3 3B 69 1D F3 8B AB 07 6B C5 58",
        .plain   = "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00",
        .cipher  = "46 F2 FB 34 2D 6F 0A B4 77 47 6F C5 01 24 2C 5F",
        .init    = rijndael_init,
        .encrypt = rijndael_encrypt,
        .decrypt = rijndael_decrypt,
    },
    {
        .blocksize = 16,
        .name    = "AES-256 FIPS-197",
        .key     = "00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F"
                  " 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F",
        .plain   = "00 11 22 33 44 55 66 77 88 99 AA BB CC DD EE FF",
        .cipher  = "8E A2 B7 CA 51 67 45 BF EA FC 49 90 4B 49 60 89",
        .init    = rijndael_init,
        .encrypt = rijndael_encrypt,
        .decrypt = rijndael_decrypt,
    },
#endif




};

size_t strtoba(const char *str, void *buf) {
    size_t count = 0;
    uint8_t *b = buf;
    while (*str) {
        int c = *str++;
        if (c == ' ') continue;
        if (c >= 'a') {
            c = c - 'a' + 10;
        } else if (c >= 'A') {
            c = c - 'A' + 10;
        } else {
            c = c - '0';
        }
        if ((c > 0x0F) || (c < 0)) continue;
        if (count++ & 0x01) {
            *b++ |= (uint8_t)c;
        } else {
            *b = (uint8_t)c << 4;
        }
    }
    return count;
}

void batostr(const void *buf, char *str, size_t count) {
    const char *charset = "0123456789ABCDEF";
    const uint8_t *b = buf;
    while (count--) {
        *str++ = charset[*b >> 4];
        *str++ = charset[*b & 0x0F];
        *str++ = ' ';
        b++;
    }
    *str = '\0';
}


int test(const test_t* algo) {
    int         ret = 0;
    char        msg[0x100];
    uint32_t    pt[0x80];
    uint32_t    ct[0x80];
    uint32_t    buf[0x80];
    uint8_t     key[0x80];

    printf("Testing %s ...", algo->name);

    strtoba(algo->plain, pt);
    strtoba(algo->cipher, ct);
    strtoba(algo->key, key);

    algo->init(key);
    algo->encrypt(buf, pt);
    if (memcmp(buf, ct, algo->blocksize) != 0) {
        batostr(buf, msg, algo->blocksize);
        printf("\nEncypt error.\nExpect %s\n   Got %s", algo->cipher, msg);
        ret = -1;
    }

    algo->init(key);
    algo->decrypt(buf, ct);
    if (memcmp(buf, pt, algo->blocksize) != 0) {
        batostr(buf, msg, algo->blocksize);
        printf("\nDecrypt error.\nExpect %s\n   Got %s", algo->plain, msg);
        ret = -1;
    }
    printf(" %s\n", (ret == 0) ? "PASS" : "\nFAIL");
    return ret;
}

int main(int argc, char **argv) {
    int ret = 0;
    for (int i = 0; i < _countof(data); i++) {
        ret |= test(&data[i]);
    }
    return ret;
}