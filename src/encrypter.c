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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "getopt.h"
#include "config.h"
#include "crypto.h"
#include "checksum.h"


static void exithelp(void) {
    printf("Usage: fwcrypt [options] -i infile -o outfile\n"
           "\t -e Encrypt (default)\n"
           "\t -d Decrypt\n"
           "\t -n No output (dry run)\n"
           "\t -c Without checksum signature\n"

    );
    exit(0);
}

static char *strsign(const void *data, size_t len) {
    static char s[0x100];
    char *t = s;
    static const char *digits = "0123456789ABCDEF";
    const uint8_t *buf = data;
    while(len--) {
        *t++ = digits[*buf >> 4];
        *t++ = digits[*buf & 0x0F];
        buf++;
    }
    *t = '\0';
    return s;
}



int main(int argc, char **argv)
{
    int dir = 1;
    int crc = 1;
    int dry = 0;
    char *infile = NULL;
    char *outfile = NULL;
    int c;

    opterr = 0;

    while ((c = getopt(argc, argv, "edchni:o:")) != -1)
        switch (c)
        {
        case 'e':
            dir = 1;
            break;
        case 'd':
            dir = 0;
            break;
        case 'c':
            crc = 0;
            break;
        case 'n':
            dry = 1;
            break;
        case 'i':
            infile = optarg;
            break;
        case 'o':
            outfile = optarg;
            break;
        case 'h':
        case '?':
            exithelp();
            break;
        default:
            exit(-1);
        }

    if (infile == NULL) {
        exithelp();
    }

    FILE *fi = fopen(infile, "rb");
    if (fi == NULL) {
        printf("Failed to open file: %s\n", argv[optind]);
        exit(1);
    }

    fseek(fi, 0, SEEK_END);
    size_t length = ftell(fi);
    fseek(fi, 0, SEEK_SET);


    size_t   blen = length + 0x1000;
    uint32_t *buf = malloc(blen);
    uint8_t  *buf8 = (uint8_t*)buf;

    if (buf == NULL) {
        printf("Failed to allocate buffer. length %zd\n", blen);
        exit(3);
    }

    if (length != fread(buf, 1, length, fi)) {
        printf("Failed to read input file.");
        exit(4);
    }
    fclose(fi);

    aes_init();
    if (dir) {
#if (DFU_VERIFY_CHECKSUM != _DISABLE)
        if (crc) {
            size_t newlen = append_checksum(buf, length, blen);

            printf("Firmware length: %zd bytes, signature: (%s) %s\n",
                   length,
                   checksum_name,
                   strsign(&buf8[length], checksum_length)
                  );

            printf("Validating firmware signature. ");
            size_t checked_length = validate_checksum(buf, blen);

            if (checked_length != length ) {
                printf("FAIL. Collision found at offset %zd\n", checked_length);
                exit(-3);
            } else {
                printf("OK.\n");
            }
            length = newlen;
        }
#endif

#if(DFU_CIPHER != _DISABLE)
        if (length % aes_blksize) {
            length += (aes_blksize - (length % aes_blksize));
        }
        printf("Encrypting %zd bytes using %s cipher.\n", length, aes_name);
        aes_encrypt(buf, buf, length);
#endif

    } else {

#if(DFU_CIPHER != _DISABLE)
        printf("Decrypting %zd bytes using %s cipher.\n", length, aes_name);
        aes_decrypt(buf, buf, length);
#endif

#if (DFU_VERIFY_CHECKSUM != _DISABLE)
        if (crc) {
            size_t checked_length = validate_checksum(buf, blen);
            if (checked_length == 0) {
                printf("No valid signature found.\n");
            } else {
                printf("Valid signature (%s) %s found at offset %zd\n",
                        checksum_name,
                        strsign(&buf8[checked_length], checksum_length),
                        checked_length
                      );
                length = checked_length;
            }
        }
#endif

    }
    if (dry || outfile == NULL) {
        printf("Writing %zd bytes. Dry run.\n", length);
    } else {
        FILE *fo = fopen(outfile, "wb");
        if (fo == NULL) {
            printf("Failed to open file: %s\n", argv[optind]);
            exit(2);
        }

        fwrite(buf, 1, length, fo);
        fclose(fo);
    }
    free(buf);
    return 0;
}
